import {binding} from "./binding.ts";

type Endian = "le" | "be";

export function bytesToBigint(bytes: Uint8Array, endian: Endian = "le"): bigint {
    if (bytes.length > 8) throw new Error("Cannot convert more than 8 bytes");
    return binding.bytes_to_u64(bytes, bytes.length, endian === "le");
}

export function bytesToInt(bytes: Uint8Array, endian: Endian = "le"): number {
    if (bytes.length > 8) throw new Error("Cannot convert more than 8 bytes");
    return binding.bytes_to_u64_fast(bytes, bytes.length, endian === "le") ?? 0;
}

export function intToBytes(value: number | bigint, length: number, endian: Endian = "le"): Uint8Array {
    if (length > 8) throw new Error("Cannot convert more than 8 bytes");
    const out = new Uint8Array(length);
    const result = binding.u64_to_bytes(value, out, length, endian === "le");
    if (result < 0) {
        throw new Error("Failed to convert number to bytes");
    }
    return out;
}
