import {afterAll, describe, expect, it} from "bun:test";
import {PUBLIC_KEY_COMPRESS_SIZE, PUBLIC_KEY_SIZE} from "../../src/blst.ts";
import {PublicKey} from "../../src/blst.ts";
import {SecretKey} from "../../src/blst.ts";
import {G1_POINT_AT_INFINITY, SECRET_KEY_BYTES, invalidInputs, validPublicKey} from "./__fixtures__/index.js";
import {expectEqualHex, expectNotEqualHex, sullyUint8Array} from "./utils/helpers.js";

describe("PublicKey", () => {
	it("should exist", () => {
		expect(PublicKey).toBeFunction();
	});

	describe("constructors", () => {
		// no need "should have a private constructor"

		describe("deserialize", () => {
			it("should only take 48 or 96 bytes", () => {
				expect(() => PublicKey.fromBytes(Buffer.alloc(32, "*"))).toThrow("Invalid encoding");
			});
			it("should take compressed byte arrays", () => {
				expectEqualHex(PublicKey.fromBytes(validPublicKey.compressed).toBytes(), validPublicKey.compressed);
			});

			describe("argument validation", () => {
				for (const [type, invalid] of invalidInputs) {
					it(`should throw on invalid pkBytes type: ${type}`, () => {
						expect(() => PublicKey.fromBytes(invalid)).toThrow();
					});
				}
				it("should throw incorrect length pkBytes", () => {
					expect(() => PublicKey.fromBytes(Buffer.alloc(12, "*"))).toThrow("Invalid encoding");
				});
			});
			it("should throw on invalid key", () => {
				try {
					PublicKey.fromBytes(sullyUint8Array(validPublicKey.compressed), true);
					throw new Error("Did not throw error for badPublicKey");
				} catch (e) {
					expect(
						e.message === "PointNotOnCurve" || e.message === "BadEncoding"
					).toBeTrue();
				}
			});
			it("should throw on zero key", () => {
				expect(() => PublicKey.fromBytes(Buffer.from(G1_POINT_AT_INFINITY))).toThrow("Invalid encoding");
			});
		});
	});

	describe("methods", () => {
		describe("toBytes", () => {
			const sk = SecretKey.fromBytes(SECRET_KEY_BYTES);
			const pk = sk.toPublicKey();
			it("should toBytes the key to Uint8Array", () => {
				expect(pk.toBytes()).toBeInstanceOf(Uint8Array);
			});
			it("should serialize uncompressed to the correct length", () => {
				expect(pk.toBytes()).toHaveLength(PUBLIC_KEY_COMPRESS_SIZE);
			});
		});
		describe("toHex", () => {
			it("should toHex string correctly", () => {
				const key = PublicKey.fromBytes(validPublicKey.compressed);
				expectEqualHex(key.toHex(true), validPublicKey.compressed);
			});
		});
		describe("keyValidate()", () => {
			it("should not throw on valid public key", () => {
				const pk = PublicKey.fromBytes(validPublicKey.compressed, true);
				expect(pk.keyValidate()).toBeUndefined();
			});
		});
	});
});

afterAll(() => {
	// TODO: enable this on all tests cause "segmentation fault" on CI
	// closeBinding();
});
