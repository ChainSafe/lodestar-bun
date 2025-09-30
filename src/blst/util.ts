import {throwErr} from "../common.ts";

export function toHex(buffer: Uint8Array | Parameters<typeof Buffer.from>[0]): string {
	if (Buffer.isBuffer(buffer)) {
		return "0x" + buffer.toString("hex");
	}

	if (buffer instanceof Uint8Array) {
		return "0x" + Buffer.from(buffer.buffer, buffer.byteOffset, buffer.length).toString("hex");
	}

	return "0x" + Buffer.from(buffer).toString("hex");
}

export function fromHex(hex: string): Uint8Array {
	const b = Buffer.from(hex.replace("0x", ""), "hex");
	return new Uint8Array(b.buffer, b.byteOffset, b.length);
}

export function assertSuccess(blstErrorCode: number): void {
	if (blstErrorCode !== 0) {
		throw throwErr(blstErrorCode);
	}
}

import {type Pointer, read} from "bun:ffi";
