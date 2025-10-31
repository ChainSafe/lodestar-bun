import {afterAll, describe, expect, it} from "bun:test";
import {SecretKey, Signature, SIGNATURE_LENGTH_COMPRESSED, SIGNATURE_LENGTH_UNCOMPRESSED} from "../../src/blst.ts";
import {KEY_MATERIAL, invalidInputs, validSignature} from "./__fixtures__/index.js";
import {expectEqualHex, expectNotEqualHex, sullyUint8Array} from "./utils/helpers.js";

describe("Signature", () => {
	it("should exist", () => {
		expect(Signature).toBeFunction();
	});
	describe("constructor", () => {
		describe("Signature.fromBytes()", () => {
			it("should take compressed byte arrays", () => {
				expectEqualHex(Signature.fromBytes(validSignature.compressed).toBytes(), validSignature.compressed);
			});
			describe("argument validation", () => {
				//	for (const [type, invalid] of invalidInputs) {
				//		it(`should throw on invalid pkBytes type: ${type}`, () => {
				//			expect(() => Signature.fromBytes(invalid)).toThrow();
				//		});
				//	}
				it("should only take 96 or 192 bytes", () => {
					expect(() => Signature.fromBytes(Buffer.alloc(32, "*"))).toThrow("BadEncoding");
				});
			});
			it("should throw on invalid key", () => {
				expect(() => Signature.fromBytes(sullyUint8Array(validSignature.compressed))).toThrow("BadEncoding");
			});
		});
	});

	describe("methods", () => {
		describe("toBytes", () => {
			const sig = SecretKey.fromKeygen(KEY_MATERIAL).sign(Buffer.from("some fancy message"));
			it("should toBytes the signature to Uint8Array", () => {
				expect(sig.toBytes()).toBeInstanceOf(Uint8Array);
			});
			it("should serialize compressed to the correct length", () => {
				expect(sig.toBytes()).toHaveLength(SIGNATURE_LENGTH_COMPRESSED);
			});
		});
		describe("toHex", () => {
			it("should toHex string correctly", () => {
				const key = Signature.fromBytes(validSignature.compressed);
				expectEqualHex(key.toHex(true), validSignature.compressed);
			});
		});
		describe("sigValidate()", () => {
			it("should return undefined for valid", () => {
				const sig = Signature.fromBytes(validSignature.compressed);
				expect(sig.sigValidate()).toBeUndefined();
			});
			it("should throw for invalid", () => {
				const pkSeed = Signature.fromBytes(validSignature.compressed);
				const sig = Signature.fromBytes(Uint8Array.from([...pkSeed.toBytes().subarray(0, 94), ...Buffer.from("a1")]));
				expect(() => sig.sigValidate()).toThrow("PointNotInGroup");
			});
		});
	});
});

