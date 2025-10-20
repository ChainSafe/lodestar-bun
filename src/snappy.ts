import {read, type Pointer} from "bun:ffi";
import {binding} from "./binding.ts";
import {throwErr} from "./common.ts";

// ptr to hold error codes from zig binding
const errPtr = binding.leveldb_get_err_ptr() as Pointer;

export function snappyCompress(input: Uint8Array): Uint8Array {
  const maxCompressedLength = binding.snappy_max_compressed_length_(input.length) as number;
  const output = new Uint8Array(maxCompressedLength);
  const outputLength = binding.snappy_compress_(
    input,
    input.length,
    output,
    output.length,
  );
  if (outputLength === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return output.subarray(0, outputLength as number);
}

export function snappyCompressInto(input: Uint8Array, output: Uint8Array): number {
  const outputLength = binding.snappy_compress_(
    input,
    input.length,
    output,
    output.length,
  );
  if (outputLength === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return outputLength as number;
}

export function snappyUncompress(input: Uint8Array): Uint8Array {
  const uncompressedLength = binding.snappy_uncompressed_length_(
    input,
    input.length,
  ) as number;
  const output = new Uint8Array(uncompressedLength);
  const outputLength = binding.snappy_uncompress_(
    input,
    input.length,
    output,
    output.length,
  );
  if (outputLength === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return output;
}

export function snappyUncompressInto(
  input: Uint8Array,
  output: Uint8Array,
): number {
  const outputLength = binding.snappy_uncompress_(
    input,
    input.length,
    output,
    output.length,
  );
  if (outputLength === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return outputLength as number;
}

export function snappyUncompressedLength(input: Uint8Array): number {
  const length = binding.snappy_uncompressed_length_(
    input,
    input.length,
  );
  if (length === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return length as number;
}

export function snappyMaxCompressedLength(sourceLength: number): number {
  return binding.snappy_max_compressed_length_(sourceLength) as number;
}

export function snappyValidateCompressedBuffer(input: Uint8Array): void {
  const result = binding.snappy_validate_compressed_buffer_(
    input,
    input.length,
  );
  throwErr(result);
}
