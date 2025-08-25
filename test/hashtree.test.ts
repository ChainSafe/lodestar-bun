import {describe, expect, test} from "bun:test";

import {createHash} from "node:crypto";
import {hash, hashInto} from "../src/hashtree.ts";

const CHUNK_SIZE = 64;

function nodeCryptoHash(input: Buffer): Uint8Array {
  if (input.length % CHUNK_SIZE !== 0) throw new Error(`input must be a multiple of ${CHUNK_SIZE} bytes`);

  const output = new Uint8Array(input.length / 2);

  for (let i = 0; i < input.length; i += CHUNK_SIZE) {
    const chunk = input.slice(i, i + CHUNK_SIZE);
    const hash = createHash("sha256").update(chunk).digest();
    output.set(hash, i / 2);
  }

  return output;
}

function nodeCryptoHashInto(input: Buffer, output: Buffer): void {
  if (input.length % CHUNK_SIZE !== 0) throw new Error(`input must be a multiple of ${CHUNK_SIZE} bytes`);
  if (output.length !== input.length / 2) throw new Error("output must be half the size of input");

  for (let i = 0; i < input.length; i += CHUNK_SIZE) {
    const chunk = input.slice(i, i + CHUNK_SIZE);
    const hash = createHash("sha256").update(chunk).digest();
    output.set(hash, i / 2);
  }
}

describe("hash should be equivalent to node:crypto", () => {
  for (let i = 1; i <= 16; i++) {
    test(`No of Chunks=${i}`, () => {
      for (let j = 0; j < 255; j++) {
        const input = Buffer.alloc(CHUNK_SIZE * i, j);
        expect(hash(input)).toEqual(nodeCryptoHash(input));
        // expectEqualHex(hash(input), nodeCryptoHash(input));
      }
    });
  }
});

describe("hashInto should be equivalent to node:crypto", () => {
  for (let i = 1; i <= 16; i++) {
    test(`No of Chunks=${i}`, () => {
      for (let j = 0; j < 255; j++) {
        const input = Buffer.alloc(CHUNK_SIZE * i, j);
        const output1 = Buffer.alloc((CHUNK_SIZE / 2) * i);
        const output2 = Buffer.alloc((CHUNK_SIZE / 2) * i);

        nodeCryptoHashInto(input, output2);
        hashInto(input, output1);
        expect(output1).toEqual(output2);
      }
    });
  }
});
