import { describe, it, expect } from "bun:test";
import {
  compress,
  compressInto,
  uncompress,
  uncompressInto,
  uncompressedLength,
  maxCompressedLength,
  validateCompressedBuffer,
} from "../src/snappy.ts";

describe("snappy", () => {
  const testData = new Uint8Array(Buffer.from("The quick brown fox jumps over the lazy dog."));
  const compressed = compress(testData);

  it("should compress into buffer", () => {
    const output = new Uint8Array(maxCompressedLength(testData.length));
    const length = compressInto(testData, output);
    expect(output.subarray(0, length) as Uint8Array).toEqual(compressed);
  });

  it("should uncompress data", () => {
    const uncompressed = uncompress(compressed);
    expect(uncompressed).toEqual(testData);
  });

  {
    it("should fail to uncompress data if max length is exceeded", () => {
      expect(() => uncompress(compressed, testData.length - 1)).toThrow();
    });

    it("should uncompress data if max length is equal to uncompressed length", () => {
      const uncompressed = uncompress(compressed, testData.length);
      expect(uncompressed).toEqual(testData);
    });

    it("should uncompress data if max length is greater than uncompressed length", () => {
      const uncompressed = uncompress(compressed, testData.length + 1);
      expect(uncompressed).toEqual(testData);
    });
  }

  it("should uncompress into buffer", () => {
    const output = new Uint8Array(testData.length);
    const length = uncompressInto(compressed, output);
    expect(length).toBe(testData.length);
    expect(output.subarray(0, length)).toEqual(testData);
  });

  it("should get uncompressed length", () => {
    const length = uncompressedLength(compressed);
    expect(length).toBe(testData.length);
  });

  it("should get max compressed length", () => {
    const maxLength = maxCompressedLength(testData.length);
    expect(maxLength).toBeGreaterThanOrEqual(compressed.length);
  });

  it("should validate compressed buffer", () => {
    expect(() => validateCompressedBuffer(compressed)).not.toThrow();
    expect(() => validateCompressedBuffer(new Uint8Array([99, 99, 99]))).toThrow();
  });
});
