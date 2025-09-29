import * as cs from "@chainsafe/hashtree";
import * as as from "@chainsafe/as-sha256";
import * as bun from "../src/hashtree.ts";

import {describe, bench} from "@chainsafe/benchmark";

describe("hashtree", () => {
  for (const L of [64, 256, 1024]) {
    const data = new Uint8Array(L);
    bench(`hash - ${L} - lodestar-bun`, () => {
      bun.hash(data);
    });
    bench(`hash - ${L} - @chainsafe/hashtree`, () => {
      cs.hash(data);
    });
    bench(`hash - ${L} - @chainsafe/as-sha256`, () => {
      as.digest(data);
    });
  }
  {
  const data = new Uint8Array(64);
  const a = new Uint8Array(32);
  const b = new Uint8Array(32);
    bench("digest64 - lodestar-bun", () => {
      bun.digest64(data);
    });
    bench("digest64 - @chainsafe/as-sha256", () => {
      as.digest64(data);
    });
    bench("digest2Bytes32 - lodestar-bun", () => {
      bun.digest2Bytes32(a, b);
    });
    bench("digest2Bytes32 - @chainsafe/as-sha256", () => {
      as.digest2Bytes32(a, b);
    });
  }
});
