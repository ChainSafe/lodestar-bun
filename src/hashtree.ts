import {binding} from "./binding.ts";
import { throwErr } from "./common.ts";

export function hash(input: Uint8Array): Uint8Array {
  if (input.length % 64 !== 0) {
    throw new Error("Input length must be a multiple of 64 bytes");
  }
  const out = new Uint8Array(input.length / 2);
  const count = input.length / 64;
  throwErr(binding.hashtree_hash_(out, input, count));
  return out;
}

export function hashInto(input: Uint8Array, output: Uint8Array): void {
  if (input.length % 64 !== 0) {
    throw new Error("Input length must be a multiple of 64 bytes");
  }
  if (output.length !== input.length / 2) {
    throw new Error("Output length must be half of input length");
  }
  const count = input.length / 64;
  throwErr(binding.hashtree_hash_(output, input, count));
}