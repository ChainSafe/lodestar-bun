import {describe, expect, test} from "bun:test";

import {Signature} from "../src/blst/index.ts";
describe("signature", () => {

    it("should exist", () => {
            expect(Signature).toBeFunction();
    });

});
