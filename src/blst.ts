export * from "./blst/publicKey.ts";
export * from "./blst/secretKey.ts";
export * from "./blst/signature.ts";
export * from "./blst/aggregateWithRandomness.ts";
export * from "./blst/verifyMultipleAggregateSignatures.ts";
export * from "./blst/aggregate.ts";
export * from "./blst/const.ts";

import { binding } from "./binding.ts";

export function init() {
  const res = binding.init();
  if (res !== 0) {
    throw new Error("Failed to initialize Zig binding");
  }
}
