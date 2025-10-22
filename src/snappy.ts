import {read, type Pointer} from "bun:ffi";
import {binding} from "./binding.ts";
import {throwErr} from "./common.ts";

// ptr to hold error codes from zig binding
const errPtr = binding.snappy_get_err_ptr() as Pointer;

export function compress(input: Uint8Array): Uint8Array {
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

export function compressInto(input: Uint8Array, output: Uint8Array): number {
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

export function uncompress(input: Uint8Array, maxLength?: number): Uint8Array {
  const uncompressedLength = binding.snappy_uncompressed_length_(
    input,
    input.length,
  ) as number;
  if (maxLength != null && uncompressedLength > maxLength) {
    throw new Error(`Uncompressed length (${uncompressedLength}) exceeds maximum length (${maxLength})`);
  }
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

export function uncompressInto(
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

export function uncompressedLength(input: Uint8Array): number {
  const length = binding.snappy_uncompressed_length_(
    input,
    input.length,
  );
  if (length === null) {
    throwErr(read.i32(errPtr, 0));
  }
  return length as number;
}

export function maxCompressedLength(sourceLength: number): number {
  return binding.snappy_max_compressed_length_(sourceLength) as number;
}

export function validateCompressedBuffer(input: Uint8Array): void {
  const result = binding.snappy_validate_compressed_buffer_(
    input,
    input.length,
  );
  throwErr(result);
}
