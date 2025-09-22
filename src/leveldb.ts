import {toArrayBuffer, type Pointer} from "bun:ffi";
import {binding} from "./binding.ts";
import {throwErr} from "./common.ts";

// Buffers to hold length and error codes from zig binding
const lenBuf = new Uint32Array(1);
const errBuf = new Int32Array(1);
binding.leveldb_set_len_ptr(lenBuf);
binding.leveldb_set_err_ptr(errBuf);

const textEncoder = new TextEncoder();

export type DB = number & {"leveldb_db": never};

export function dbOpen(path: string, options: {
  create_if_missing?: boolean;
  error_if_exists?: boolean;
  paranoid_checks?: boolean;
  write_buffer_size?: number;
  max_open_files?: number;
  block_size?: number;
  block_restart_interval?: number;
} = {
}): DB {
  const db = binding.leveldb_db_open(
    textEncoder.encode(path + "\0"),
    options.create_if_missing ?? false,
    options.error_if_exists ?? false,
    options.paranoid_checks ?? true,
    options.write_buffer_size ?? 4 * 1024 * 1024,
    options.max_open_files ?? 1000,
    options.block_size ?? 4 * 1024,
    options.block_restart_interval ?? 16,
  );
  if (db === null) {
    throwErr(errBuf[0] as number);
  }
  return db as number as DB;

}

export function dbClose(db: DB): void {
  binding.leveldb_db_close(db);
}

export function dbPut(db: DB, key: Uint8Array, value: Uint8Array): void {
  throwErr(binding.leveldb_db_put(
    db,
    key,
    key.length,
    value,
    value.length,
  ));
}


const data_finalizer = new FinalizationRegistry((data_ptr: number) => {
  binding.leveldb_free_(data_ptr as Pointer);
});

export function dbGet(db: DB, key: Uint8Array): Uint8Array | null {
  const valuePtr = binding.leveldb_db_get(
    db,
    key,
    key.length,
  );
  if (valuePtr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  const valueLen = lenBuf[0];
  const valueBuffer = toArrayBuffer(
    valuePtr,
    0,
    valueLen,
  );
  const value = new Uint8Array(valueBuffer);
  data_finalizer.register(valueBuffer, valuePtr);
  return value;
}

export function dbDelete(db: DB, key: Uint8Array): void {
  throwErr(binding.leveldb_db_delete(
    db,
    key,
    key.length,
  ));
}

export function dbBatchPut(db: DB, batch: {key: Uint8Array; value: Uint8Array}[]): void {
  const batchPtr = binding.leveldb_writebatch_create_() as number;
  for (const {key, value} of batch) {
    binding.leveldb_writebatch_put_(
      batchPtr,
      key,
      key.length,
      value,
      value.length,
    );
  }
  const result = binding.leveldb_db_write(db, batchPtr);
  binding.leveldb_writebatch_destroy_(batchPtr);
  throwErr(result);
}

export function dbBatchDelete(db: DB, batch: Uint8Array[]): void {
  const batchPtr = binding.leveldb_writebatch_create_() as number;
  for (const key of batch) {
    binding.leveldb_writebatch_delete_(
      batchPtr,
      key,
      key.length,
    );
  }
  const result = binding.leveldb_db_write(db, batchPtr);
  binding.leveldb_writebatch_destroy_(batchPtr);
  throwErr(result);
}

export type Iterator = number & {"leveldb_iterator": never};

export function dbIterator(db: DB): Iterator {
  return binding.leveldb_db_create_iterator(db) as number as Iterator;
}

export function iteratorDestroy(it: Iterator): void {
  binding.leveldb_iterator_destroy(it);
}

export function iteratorSeekToFirst(it: Iterator): void {
  binding.leveldb_iterator_seek_to_first(it);
}

export function iteratorSeekToLast(it: Iterator): void {
  binding.leveldb_iterator_seek_to_last(it);
}

export function iteratorSeek(it: Iterator, key: Uint8Array): void {
  binding.leveldb_iterator_seek(it, key, key.length);
}

export function iteratorNext(it: Iterator): void {
  binding.leveldb_iterator_next(it);
}

export function iteratorPrev(it: Iterator): void {
  binding.leveldb_iterator_prev(it);
}

export function iteratorValid(it: Iterator): boolean {
  return binding.leveldb_iterator_valid(it);
}

export function iteratorKey(it: Iterator): Uint8Array {
  const keyPtr = binding.leveldb_iterator_key(it);
  if (keyPtr === null) {
    throwErr(errBuf[0] as number);
  }
  const keyLen = lenBuf[0];
  return new Uint8Array(
    toArrayBuffer(
      keyPtr as Pointer,
      0,
      keyLen,
    )
  );
}

export function iteratorValue(it: Iterator): Uint8Array {
  const valuePtr = binding.leveldb_iterator_value(it);
  if (valuePtr === null) {
    throwErr(errBuf[0] as number);
  }
  const valueLen = lenBuf[0];
  return new Uint8Array(
    toArrayBuffer(
      valuePtr as Pointer,
      0,
      valueLen,
    )
  );
}

export function iteratorError(it: Iterator): void {
  throwErr(binding.leveldb_iterator_get_error(it));
}
