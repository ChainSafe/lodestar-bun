import { describe, it, expect } from "bun:test";
import {
  snappyCompress,
  snappyCompressInto,
  snappyUncompress,
  snappyUncompressInto,
  snappyUncompressedLength,
  snappyMaxCompressedLength,
  snappyValidateCompressedBuffer,
} from "../src/snappy.ts";

describe("snappy", () => {
  const testData = new Uint8Array(Buffer.from("The quick brown fox jumps over the lazy dog."));
  const compressed = snappyCompress(testData);

  it("should compress into buffer", () => {
    const output = new Uint8Array(snappyMaxCompressedLength(testData.length));
    const length = snappyCompressInto(testData, output);
    expect(output.subarray(0, length) as Uint8Array).toEqual(compressed);
  });

  it("should uncompress data", () => {
    const uncompressed = snappyUncompress(compressed);
    expect(uncompressed).toEqual(testData);
  });

  it("should uncompress into buffer", () => {
    const output = new Uint8Array(testData.length);
    const length = snappyUncompressInto(compressed, output);
    expect(length).toBe(testData.length);
    expect(output.subarray(0, length)).toEqual(testData);
  });

  it("should get uncompressed length", () => {
    const length = snappyUncompressedLength(compressed);
    expect(length).toBe(testData.length);
  });

  it("should get max compressed length", () => {
    const maxLength = snappyMaxCompressedLength(testData.length);
    expect(maxLength).toBeGreaterThanOrEqual(compressed.length);
  });

  it("should validate compressed buffer", () => {
    expect(() => snappyValidateCompressedBuffer(compressed)).not.toThrow();
    expect(() => snappyValidateCompressedBuffer(new Uint8Array([99, 99, 99]))).toThrow();
  });
});
