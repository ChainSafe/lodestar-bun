import {randomBytes} from "node:crypto";

import {describe, bench} from "@chainsafe/benchmark";

import {bytesToBigint, bytesToInt, intToBytes} from "../src/bytes.ts";
import * as other from "bigint-buffer";

describe("bytes", () => {
    bench("bytesToBigint", () => {
        bytesToBigint(randomBytes(8), "le");
    });
    bench("other.toBigIntLE", () => {
        other.toBigIntLE(randomBytes(8));
    });

    bench("intToBytes", () => {
        intToBytes(BigInt(123456789), 8, "le");
    });
    bench("other.toBufferLE", () => {
        other.toBufferLE(BigInt(123456789), 8);
    });
})
