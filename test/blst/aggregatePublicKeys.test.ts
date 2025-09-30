import {describe, expect, it} from "bun:test";
import {PublicKey, aggregatePublicKeys} from "../../src/blst/index.ts";
import {badPublicKey} from "./__fixtures__/index.js";
import {isEqualBytes} from "./utils/helpers.js";
import {getTestSets} from "./utils/testSets.js";

describe("Aggregate Public Keys", () => {
	const sets = getTestSets(10);
	const keys = sets.map(({pk}) => pk);

	describe("aggregatePublicKeys()", () => {
		it("should return a PublicKey", () => {
			const agg = aggregatePublicKeys(keys);
			expect(agg instanceof PublicKey).toBeTrue();
		});
		it("should be able to keyValidate PublicKey", () => {
			const agg = aggregatePublicKeys(keys);
			expect(agg.keyValidate() === undefined).toBeTrue();
		});
		it("should throw for invalid PublicKey", () => {
			try {
				aggregatePublicKeys(keys.concat(PublicKey.fromBytes(badPublicKey)), true);
				expect.fail("Did not throw error for badPublicKey");
			} catch (e) {
				expect(
					e.message === "PointNotOnCurve" ||
						e.message === "PointNotInGroup" ||
						e.message === "BadEncoding"
				).toBeTrue();
				// expect((e as Error).message.endsWith("Invalid key at index 10")).to.be.true;
			}
		});
		it("should return a key that is not in the keys array", () => {
			const agg = aggregatePublicKeys(keys);
			const serialized = agg.toBytes();
			expect(keys.find((key) => isEqualBytes(key.toBytes(), serialized)) === undefined).toBeTrue();
		});
	});
});
