import {afterAll, describe, expect, it} from "bun:test";
import {verifyMultipleAggregateSignatures} from "../../src/blst.ts";
import {getTestSet, getTestSets} from "./utils/testSets.js";

describe("Verify Multiple Aggregate Signatures", () => {
	describe("verifyMultipleAggregateSignatures", () => {
		it("should return a boolean", () => {
			expect(verifyMultipleAggregateSignatures([])).toBeBoolean();
		});
		it("should default to false", () => {
			expect(verifyMultipleAggregateSignatures([])).toBeFalse();
		});
		it("should return true for valid sets", () => {
			expect(verifyMultipleAggregateSignatures(getTestSets(6))).toBeTrue();
		});
		it("should return false for invalid sets", () => {
			const sets = getTestSets(6);
			const randomSet = getTestSet(20);
			// do not modify sets[0].sig directly, it will affect other tests
			sets[0] = {...sets[0], sig: randomSet.sig};
			expect(verifyMultipleAggregateSignatures(sets)).toBeFalse();
		});
	});
});

