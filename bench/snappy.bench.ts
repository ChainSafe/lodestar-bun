import { describe, bench } from "@chainsafe/benchmark";
import * as snappy from "../src/snappy.ts";
import * as other from "snappyjs";

const uncompressed = new Uint8Array(Buffer.from("The quick brown fox jumps over the lazy dog. The quick brown fox jumps over the lazy dog."));
const compressed = snappy.compress(uncompressed);

describe("snappy", () => {
  bench("compress", () => {
    snappy.compress(uncompressed);
  });

  bench("compress (other)", () => {
    other.compress(Buffer.from(uncompressed));
  });

  bench("uncompress", () => {
    snappy.uncompress(compressed);
  });

  bench("uncompress (other)", () => {
    other.uncompress(Buffer.from(compressed));
  });
});
