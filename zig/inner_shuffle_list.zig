const std = @import("std");
const Mutex = std.Thread.Mutex;
const toErrCode = @import("common.zig").toErrCode;

const stdx = @import("state_transition:stdx");

var gpa = std.heap.GeneralPurposeAllocator(.{}){};

const InnerShuffleList = stdx.InnerShuffleList;
const SEED_SIZE = stdx.SEED_SIZE;

const Error = error{
    InvalidInput,
    InvalidPointer,
    TooManyThreads,
    ThreadError,
    Error,
    Pending,
};

/// C-ABI functions for shuffle_list
/// on Ethereum consensus, shuffling is called once per epoch so this is more than enough
/// don't want to have too big value here so that we can detect issue sooner
const MAX_ASYNC_RESULT_SIZE = 4;
var mutex: Mutex = Mutex{};
var async_result_pointer_indices: [MAX_ASYNC_RESULT_SIZE]u64 = [_]u64{0} ** MAX_ASYNC_RESULT_SIZE;
var async_result_index: usize = 0;
const Status = enum {
    Pending,
    Done,
    Error,
};

/// object to store result from another thread and for bun to poll
const AsyncResult = struct {
    allocator: std.mem.Allocator,
    status: Status,
    mutex: Mutex,

    // can put any result here but no need for shuffling apis
    pub fn init(allocator: std.mem.Allocator) !*@This() {
        const instance_ptr = try allocator.create(@This());
        instance_ptr.allocator = allocator;
        instance_ptr.status = Status.Pending;
        instance_ptr.mutex = Mutex{};
        return instance_ptr;
    }

    pub fn updateStatus(self: *@This(), new_status: Status) void {
        self.mutex.lock();
        defer self.mutex.unlock();
        self.status = new_status;
    }

    // Get status safely while locking the mutex
    pub fn getStatus(self: *@This()) Status {
        self.mutex.lock();
        defer self.mutex.unlock();
        return self.status;
    }

    pub fn deinit(self: *@This()) void {
        self.allocator.destroy(self);
    }
};

/// shuffle the `active_indices` array in place asynchronously
/// return an u64 which is the index within `MAX_ASYNC_RESULT_SIZE`
/// consumer needs to poll the AsyncResult via pollAsyncResult() using that index and
/// then release the AsyncResult via releaseAsyncResult() when done
export fn asyncShuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]const u8,
    seed_len: usize,
    rounds: u8,
) usize {
    const forwards = true;
    return doAsyncShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

/// unshuffle the `active_indices` array in place asynchronously
/// return an u64 which is the index within `MAX_ASYNC_RESULT_SIZE`
/// consumer needs to poll the AsyncResult via pollAsyncResult() using that index and
/// then release the AsyncResult via releaseAsyncResult() when done
export fn asyncUnshuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]const u8,
    seed_len: usize,
    rounds: u8,
) usize {
    const forwards = false;
    return doAsyncShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

fn doAsyncShuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]const u8,
    seed_len: usize,
    rounds: u8,
    forwards: bool,
) usize {
    if (len == 0 or seed_len == 0) {
        return @intCast(toErrCode(Error.InvalidInput));
    }
    mutex.lock();
    defer mutex.unlock();
    // too many threads on-going for async result
    if (async_result_pointer_indices[(async_result_index + 1) % MAX_ASYNC_RESULT_SIZE] != 0) {
        return @intCast(toErrCode(Error.TooManyThreads));
    }
    async_result_index += 1;
    const pointer_index = async_result_index % MAX_ASYNC_RESULT_SIZE;

    const allocator = gpa.allocator();
    const result = AsyncResult.init(allocator) catch |e| return @intCast(toErrCode(e));
    async_result_pointer_indices[pointer_index] = @intFromPtr(result);

    // this is called really sparsely, so we can just spawn new thread instead of using a thread pool like in blst-z
    const thread = std.Thread.spawn(.{}, struct {
        pub fn run(
            _active_indices: [*c]u32,
            _len: usize,
            _seed: [*c]const u8,
            _seed_len: usize,
            _rounds: u8,
            _forwards: bool,
            _result: *AsyncResult,
        ) void {
            InnerShuffleList(
                u32,
                _active_indices[0.._len],
                _seed[0.._seed_len],
                _rounds,
                _forwards,
            ) catch {
                _result.updateStatus(Status.Error);
                return;
            };
            _result.updateStatus(Status.Done);
        }
    }.run, .{ active_indices, len, seed, seed_len, rounds, forwards, result }) catch return @intCast(toErrCode(Error.ThreadError));

    thread.detach();

    return pointer_index;
}

/// bun to store a pointer index
/// zig to get pointer u64 from async_result_pointer_indices and restore AsyncResult pointer
/// then release it
export fn releaseAsyncResult(pointer_index_param: usize) void {
    mutex.lock();
    defer mutex.unlock();
    const pointer_index = pointer_index_param % MAX_ASYNC_RESULT_SIZE;
    const async_result_ptr = async_result_pointer_indices[pointer_index];
    // avoid double-free
    if (async_result_ptr == 0) {
        return;
    }
    const result_ptr: *AsyncResult = @ptrFromInt(async_result_ptr);
    result_ptr.deinit();
    // native pointer cannot be 0 https://zig.guide/language-basics/pointers/
    async_result_pointer_indices[pointer_index] = 0;
}

/// bun to store a pointer index
/// zig to get pointer u64 from async_result_pointer_indices and restore AsyncResult pointer
/// then check value inside it
export fn pollAsyncResult(pointer_index_param: usize) i32 {
    mutex.lock();
    defer mutex.unlock();
    const pointer_index = pointer_index_param % MAX_ASYNC_RESULT_SIZE;
    const async_result_ptr = async_result_pointer_indices[pointer_index];
    // native pointer cannot be 0 https://zig.guide/language-basics/pointers/
    if (async_result_ptr == 0) {
        return toErrCode(Error.InvalidPointer);
    }
    const result_ptr: *AsyncResult = @ptrFromInt(async_result_ptr);
    const status = result_ptr.getStatus();
    if (status == Status.Done) {
        return 0;
    } else if (status == Status.Error) {
        return toErrCode(Error.Error);
    }
    return toErrCode(Error.Pending);
}

/// shuffle the `active_indices` array in place synchronously
export fn shuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]u8,
    seed_len: usize,
    rounds: u8,
) i32 {
    const forwards = true;
    return doShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

/// unshuffle the `active_indices` array in place synchronously
export fn unshuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]u8,
    seed_len: usize,
    rounds: u8,
) i32 {
    const forwards = false;
    return doShuffleList(active_indices, len, seed, seed_len, rounds, forwards);
}

export fn doShuffleList(
    active_indices: [*c]u32,
    len: usize,
    seed: [*c]u8,
    seed_len: usize,
    rounds: u8,
    forwards: bool,
) i32 {
    if (len == 0 or seed_len == 0) {
        return toErrCode(Error.InvalidInput);
    }

    InnerShuffleList(
        u32,
        active_indices[0..len],
        seed[0..seed_len],
        rounds,
        forwards,
    ) catch return toErrCode(Error.Error);
    return 0;
}

// more tests for async shuffle and unshuffle at bun side
test "asyncShuffleList - issue single thread and poll the result" {
    var input = [_]u32{ 0, 1, 2, 3, 4, 5, 6, 7, 8 };
    var seed = [_]u8{0} ** SEED_SIZE;
    const rounds = 32;

    const pointer_index = asyncUnshuffleList(&input[0], input.len, &seed[0], seed.len, rounds);
    defer releaseAsyncResult(pointer_index);

    // poll the AsyncResult, this should happen in less than 100ms or the test wil fail
    const start = std.time.milliTimestamp();
    while (std.time.milliTimestamp() - start < 100) {
        const status = pollAsyncResult(pointer_index);
        if (status == 0) {
            const expected = [_]u32{ 6, 2, 3, 5, 1, 7, 8, 0, 4 };
            try std.testing.expectEqualSlices(u32, expected[0..], input[0..]);
            return;
        }
        std.time.sleep(10 * std.time.ns_per_ms);
    }

    // after 100ms and still pending, this is a failure
    try std.testing.expect(false);
}
