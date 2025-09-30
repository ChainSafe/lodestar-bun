
import {afterEach, beforeEach, describe, expect, test} from "bun:test";
import * as fs from "node:fs";
import {Signature} from "../src/index.ts";


describe("Signature", () => {
  test("should eistin", () => {
    expect(Signature).toBeFunction();
  })
});

