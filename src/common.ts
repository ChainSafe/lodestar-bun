import {binding} from "./binding.ts";

export function throwErr(code: number): number {
  if (code < 0) {
    const errName = binding.err_name(-code);
    throw new Error(errName.toString());
  } else {
    return code;
  }
}