import {throwErr} from "../common.ts";

export function toHex(buffer: Uint8Array): string {
	return "0x" + buffer.toHex();
}

export function fromHex(hex: string): Uint8Array {
	return Uint8Array.fromHex(hex.replace("0x", ""));
}

export function assertSuccess(blstErrorCode: number): void {
	if (blstErrorCode !== 0) {
		throw throwErr(blstErrorCode);
	}
}
