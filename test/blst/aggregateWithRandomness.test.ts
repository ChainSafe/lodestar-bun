import {beforeAll, describe, expect, it} from "bun:test";
import {
	PublicKey,
	Signature,
	aggregatePublicKeys,
	aggregateSerializedSignatures,
	aggregateWithRandomness,
	asyncAggregateWithRandomness,
	verifyMultipleAggregateSignatures,
} from "../../src/blst.ts";
import {G1_POINT_AT_INFINITY, G2_POINT_AT_INFINITY} from "./__fixtures__/index.js";
import {expectNotEqualHex, getTestSet, getTestSetsSameMessage} from "./utils/index.js";

describe("Aggregate With Randomness", () => {
	const sameMessageSets = getTestSetsSameMessage(10);
	const msg = sameMessageSets.msg;
	const sets = sameMessageSets.sets.map((s) => ({
		msg: msg,
		pk: s.pk,
		sig: s.sig.toBytes(),
	}));
	const randomSet = getTestSet(20);
	const infinityPublicKey = Buffer.from(G1_POINT_AT_INFINITY, "hex");

	beforeAll(() => {
		// make sure sets are valid before starting
		expect(() => PublicKey.fromBytes(infinityPublicKey).keyValidate()).toThrow("PkIsInfinity");
		const sig = Signature.fromBytes(sets[0].sig);
		expect(sig.verify(msg, sets[0].pk)).toBeTrue();

		expectNotEqualHex(msg, randomSet.msg);
		expect(randomSet.sig.verify(randomSet.msg, randomSet.pk)).toBeTrue();
		expect(verifyMultipleAggregateSignatures([randomSet])).toBeTrue();
	});

	describe("aggregateWithRandomness()", () => {
		it("should not accept an empty array argument", () => {
			expect(() => aggregateWithRandomness([])).toThrow("At least one PkAndSerializedSig is required");
		});
		it("should throw for invalid serialized", () => {
			expect(() =>
				aggregateWithRandomness(
					sets.concat({
						pk: sets[0].pk,
						//TODO: (@matthewkeil) this throws error "Public key is infinity" not signature because there is only one blst error
						sig: G2_POINT_AT_INFINITY,
					} as any)
				)
			).toThrow();
		});
		it("should return a {pk: PublicKey, sig: Signature} object", () => {
			const agg = aggregateWithRandomness(sets);
			expect(agg).toBeInstanceOf(Object);

			expect(agg.pk).toBeDefined();
			expect(agg.pk).toBeInstanceOf(PublicKey);
			expect(() => agg.pk.keyValidate()).not.toThrow();

			expect(agg.sig).toBeDefined();
			expect(agg.sig).toBeInstanceOf(Signature);
			expect(() => agg.sig.sigValidate()).not.toThrow();
		});
		it("should add randomness to aggregated publicKey", () => {
			const withoutRandomness = aggregatePublicKeys(sets.map(({pk}) => pk));
			const withRandomness = aggregateWithRandomness(sets).pk;
			expectNotEqualHex(withRandomness.toBytes(), withoutRandomness.toBytes());
		});
		it("should add randomness to aggregated signature", () => {
			const withoutRandomness = aggregateSerializedSignatures(sets.map(({sig}) => sig));
			const withRandomness = aggregateWithRandomness(sets).sig;
			expectNotEqualHex(withRandomness.toBytes(), withoutRandomness.toBytes());
		});
		it("should produce verifiable set", () => {
			const {pk, sig} = aggregateWithRandomness(sets);
			expect(sig.verify(msg, pk)).toBeTrue();
		});
		it("should not validate for different message", async () => {
			const {pk, sig} = aggregateWithRandomness(sets);
			expect(sig.verify(randomSet.msg, pk)).toBeFalse();
		});
		it("should not validate included key/sig for different message", async () => {
			const {pk, sig} = aggregateWithRandomness([...sets, {pk: randomSet.pk, sig: randomSet.sig.toBytes()}]);
			expect(sig.verify(msg, pk)).toBeFalse();
		});
		it("should return different signatures for different sets", () => {
			const {pk: pk1, sig: sig1} = aggregateWithRandomness(sets);
			const {pk: pk2, sig: sig2} = aggregateWithRandomness([...sets, {pk: randomSet.pk, sig: randomSet.sig.toBytes()}]);
			expectNotEqualHex(pk1.toBytes(), pk2.toBytes());
			expectNotEqualHex(sig1.toBytes(), sig2.toBytes());
		});
		it("should return different signatures for different times", () => {
			const {pk: pk1, sig: sig1} = aggregateWithRandomness(sets);
			const {pk: pk2, sig: sig2} = aggregateWithRandomness(sets);
			expectNotEqualHex(pk1.toBytes(), pk2.toBytes());
			expectNotEqualHex(sig1.toBytes(), sig2.toBytes());
		});
	});
});
