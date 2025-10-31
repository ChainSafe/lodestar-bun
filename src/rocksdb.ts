import { JSCallback, read, toArrayBuffer, type Pointer } from "bun:ffi";
import { binding } from "./binding.ts";
import { throwErr } from "./common.ts";

// ptrs to hold length and error codes from zig binding
const lenPtr = binding.rocksdb_get_len_ptr() as Pointer;
const errPtr = binding.rocksdb_get_err_ptr() as Pointer;

const textEncoder = new TextEncoder();

export type DB = number & { rocksdb_db: never };

export function dbOpen(
  path: string,
  options: {
    create_if_missing?: boolean;
    error_if_exists?: boolean;
    paranoid_checks?: boolean;
    write_buffer_size?: number;
    max_open_files?: number;
  } = {}
): DB {
  const db = binding.rocksdb_db_open(
    textEncoder.encode(path + "\0"),
    options.create_if_missing ?? false,
    options.error_if_exists ?? false,
    options.paranoid_checks ?? true,
    options.write_buffer_size ?? 4 * 1024 * 1024,
    options.max_open_files ?? 1000
  );
  if (db === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return db as number as DB;
}

export function dbClose(db: DB): void {
  binding.rocksdb_db_close(db);
}

export function dbDestroy(path: string): void {
  throwErr(binding.rocksdb_db_destroy(textEncoder.encode(path + "\0")));
}

export function dbPut(db: DB, key: Uint8Array, value: Uint8Array): void {
  throwErr(binding.rocksdb_db_put(db, key, key.length, value, value.length));
}

export function dbGet(db: DB, key: Uint8Array): Uint8Array | null {
  const valuePtr = binding.rocksdb_db_get(db, key, key.length);
  if (valuePtr === null) {
    throwErr(read.i32(errPtr, 0));
    return null;
  }
  const valueLen = read.u32(lenPtr, 0);
  const value = new Uint8Array(toArrayBuffer(valuePtr, 0, valueLen).slice());
  binding.rocksdb_free_(valuePtr);
  return value;
}

export function dbDelete(db: DB, key: Uint8Array): void {
  throwErr(binding.rocksdb_db_delete(db, key, key.length));
}

export function dbBatchPut(
  db: DB,
  batch: { key: Uint8Array; value: Uint8Array }[]
): void {
  const batchPtr = binding.rocksdb_writebatch_create_();
  for (const { key, value } of batch) {
    binding.rocksdb_writebatch_put_(
      batchPtr,
      key,
      key.length,
      value,
      value.length
    );
  }
  const result = binding.rocksdb_db_write(db, batchPtr);
  binding.rocksdb_writebatch_destroy_(batchPtr);
  throwErr(result);
}

export function dbBatchDelete(db: DB, batch: Uint8Array[]): void {
  const batchPtr = binding.rocksdb_writebatch_create_();
  for (const key of batch) {
    binding.rocksdb_writebatch_delete_(batchPtr, key, key.length);
  }
  const result = binding.rocksdb_db_write(db, batchPtr);
  binding.rocksdb_writebatch_destroy_(batchPtr);
  throwErr(result);
}

export type Iterator = number & { rocksdb_iterator: never };

export function dbIterator(db: DB): Iterator {
  return binding.rocksdb_db_create_iterator(db) as number as Iterator;
}

export function iteratorDestroy(it: Iterator): void {
  binding.rocksdb_iterator_destroy(it);
}

export function iteratorSeekToFirst(it: Iterator): void {
  binding.rocksdb_iterator_seek_to_first(it);
}

export function iteratorSeekToLast(it: Iterator): void {
  binding.rocksdb_iterator_seek_to_last(it);
}

export function iteratorSeek(it: Iterator, key: Uint8Array): void {
  binding.rocksdb_iterator_seek(it, key, key.length);
}

export function iteratorNext(it: Iterator): void {
  binding.rocksdb_iterator_next(it);
}

export function iteratorPrev(it: Iterator): void {
  binding.rocksdb_iterator_prev(it);
}

export function iteratorValid(it: Iterator): boolean {
  return binding.rocksdb_iterator_valid(it);
}

export function iteratorKey(it: Iterator): Uint8Array {
  const keyPtr = binding.rocksdb_iterator_key(it);
  if (keyPtr === null) {
    throwErr(read.i32(errPtr, 0));
  }
  const keyLen = read.u32(lenPtr, 0);
  return new Uint8Array(toArrayBuffer(keyPtr as Pointer, 0, keyLen).slice());
}

export function iteratorValue(it: Iterator): Uint8Array {
  const valuePtr = binding.rocksdb_iterator_value(it);
  if (valuePtr === null) {
    throwErr(read.i32(errPtr, 0));
  }
  const valueLen = read.u32(lenPtr, 0);
  return new Uint8Array(
    toArrayBuffer(valuePtr as Pointer, 0, valueLen).slice()
  );
}

export function iteratorError(it: Iterator): void {
  throwErr(binding.rocksdb_iterator_get_error(it));
}
