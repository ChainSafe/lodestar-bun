import { toArrayBuffer, type Pointer } from "bun:ffi";
import {binding} from "./binding.ts";
import { throwErr } from "./common.ts";

// Buffers to hold length and error codes from zig binding
const lenBuf = new Uint32Array(1);
const errBuf = new Int32Array(1);
binding.lmdb_set_len_ptr(lenBuf);
binding.lmdb_set_err_ptr(errBuf);

const textEncoder = new TextEncoder();

/**
 * LMDB environment handle.
 */
export type Environment = number & {["lmdb_environment"]: never};

/**
 * Initialize an LMDB environment.
 * @param path The file path to the database directory.
 * @param options Optional settings for the environment.
 * @returns The initialized environment handle.
 */
export function environmentInit(path: string, options: { mapSize?: number; maxDbs?: number } = {}): Environment {
  const env = binding.lmdb_environment_init(textEncoder.encode(path + "\0"), options.maxDbs ?? 64, options.mapSize ?? 1024 * 1024 * 1024);
  if (env === null) {
    throwErr(errBuf[0] as number);
  }
  return env as number as Environment;
}

/**
 * Deinitialize an LMDB environment.
 * @param env The environment handle to deinitialize.
 */
export function environmentDeinit(env: Environment): void {
  binding.lmdb_environment_deinit(env);
}

/**
 * LMDB transaction handle.
 */
export type Transaction = number & {["lmdb_transaction"]: never};

/**
 * Begin a new transaction.
 * @param env The environment handle.
 * @param readOnly Whether the transaction is read-only. Default is true.
 * @returns The started transaction handle.
 */
export function transactionBegin(env: Environment, readOnly = true): Transaction {
  const txn = binding.lmdb_transaction_begin(env as number as Pointer, readOnly);
  if (txn === null) {
    throwErr(errBuf[0] as number);
  }
  return txn as number as Transaction;
}

/**
 * Commit a transaction.
 * This will persist any changes to the database.
 * @param txn The transaction handle to commit.
 */
export function transactionCommit(txn: Transaction): void {
  throwErr(binding.lmdb_transaction_commit(txn as number as Pointer));
}

/**
 * Abort a transaction.
 * This will discard any changes made during the transaction.
 * @param txn The transaction handle to abort.
 */
export function transactionAbort(txn: Transaction): void {
  binding.lmdb_transaction_abort(txn as number as Pointer);
}

/**
 * LMDB database handle.
 */
export type Database = number & {["lmdb_database"]: never};

/**
 * Open a database within a transaction.
 * @param txn The transaction handle.
 * @param name The name of the database.
 * @param options Optional settings for the database.
 * @param options.create Whether to create the database if it doesn't exist. Default is false.
 * @param options.integerKey Whether the database uses integer keys. Default is false.
 * @param options.reverseKey Whether the database uses reverse keys. Default is false.
 * @returns The opened database handle.
 */
export function databaseOpen(txn: Transaction, name: string | null, { create = false, integerKey = false, reverseKey = false } = {} ): Database {
  const dbi = binding.lmdb_database_open(txn as number as Pointer, name ? textEncoder.encode(name + "\0") : null, create, integerKey, reverseKey);
  if (dbi === 0) {
    throwErr(errBuf[0] as number);
  }
  return dbi as number as Database;
}

/**
 * Get a value from the database by key.
 * 
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param txn The transaction handle.
 * @param db The database handle.
 * @param key The key to retrieve.
 * @returns The value associated with the key, or null if not found.
 */
export function databaseGet(txn: Transaction, db: Database, key: Uint8Array): Uint8Array | null {
  const ptr = binding.lmdb_database_get(txn as number as Pointer, db as number as Pointer, key, key.length);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr, 0, lenBuf[0]));
}

/**
 * Set a value in the database.
 * @param txn The transaction handle.
 * @param db The database handle.
 * @param key The key to set.
 * @param value The value to associate with the key.
 */
export function databaseSet(txn: Transaction, db: Database, key: Uint8Array, value: Uint8Array): void {
  throwErr(binding.lmdb_database_set(txn as number as Pointer, db as number as Pointer, key, key.length, value, value.length));
}

/**
 * Delete a key from the database.
 * @param txn The transaction handle.
 * @param db The database handle.
 * @param key The key to delete.
 */
export function databaseDelete(txn: Transaction, db: Database, key: Uint8Array): void {
  throwErr(binding.lmdb_database_delete(txn as number as Pointer, db as number as Pointer, key, key.length));
}

/**
 * LMDB cursor handle.
 */
export type Cursor = number & {["lmdb_cursor"]: never};

/**
 * Create a cursor for iterating over database entries.
 * @param txn The transaction handle.
 * @param db The database handle.
 * @returns The created cursor handle.
 */
export function databaseCursor(txn: Transaction, db: Database): Cursor {
  const cursor = binding.lmdb_database_cursor(txn as number as Pointer, db as number as Pointer) as number;
  return throwErr(cursor) as Cursor;
}

/**
 * Deinitialize a cursor.
 * @param cursor The cursor handle to deinitialize.
 */
export function cursorDeinit(cursor: Cursor): void {
  binding.lmdb_cursor_deinit(cursor as number as Pointer);
}

/**
 * Get the current key the cursor is pointing to.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The current key.
 */
export function cursorGetCurrentKey(cursor: Cursor): Uint8Array {
  const ptr = binding.lmdb_cursor_get_current_key(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
  }
  return new Uint8Array(toArrayBuffer(ptr as Pointer, 0, lenBuf[0]));
}

/**
 * Get the current value the cursor is pointing to.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The current value.
 */
export function cursorGetCurrentValue(cursor: Cursor): Uint8Array {
  const ptr = binding.lmdb_cursor_get_current_value(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
  }
  return new Uint8Array(toArrayBuffer(ptr as Pointer, 0, lenBuf[0]));
}

/**
 * Move the cursor to the next entry in the database.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The next key the cursor points to, or null if at the end.
 */
export function cursorGoToNext(cursor: Cursor): Uint8Array | null {
  const ptr = binding.lmdb_cursor_go_to_next(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr, 0, lenBuf[0]));
}

/**
 * Move the cursor to the previous entry in the database.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The previous key the cursor points to, or null if at the beginning.
 */
export function cursorGoToPrevious(cursor: Cursor): Uint8Array | null {
  const ptr = binding.lmdb_cursor_go_to_previous(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr, 0, lenBuf[0]));
}

/**
 * Move the cursor to the first entry in the database.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The first key the cursor points to, or null if the database is empty.
 */
export function cursorGoToFirst(cursor: Cursor): Uint8Array | null {
  const ptr = binding.lmdb_cursor_go_to_first(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr, 0, lenBuf[0]));
}

/**
 * Move the cursor to the last entry in the database.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @returns The last key the cursor points to, or null if the database is empty.
 */
export function cursorGoToLast(cursor: Cursor): Uint8Array | null {
  const ptr = binding.lmdb_cursor_go_to_last(cursor as number as Pointer);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr, 0, lenBuf[0]));
}

/**
 * Move the cursor to a specific key in the database.
 * @param cursor The cursor handle.
 * @param key The key to move to.
 */
export function cursorGoToKey(cursor: Cursor, key: Uint8Array): void {
  throwErr(binding.lmdb_cursor_go_to_key(cursor as number as Pointer, key, key.length));
}

/**
 * Seek the cursor to the first entry greater than or equal to the specified key.
 *
 * The memory pointed to by the returned values is owned by the database. The caller need not dispose of the memory, and may not modify it in any way. For values returned in a read-only transaction any modification attempts will cause a SIGSEGV. 
 * Values returned from the database are valid only until a subsequent update operation, or the end of the transaction. 
 * @param cursor The cursor handle.
 * @param key The key to seek to.
 * @returns The key the cursor points to after seeking, or null if not found.
 */
export function cursorSeek(cursor: Cursor, key: Uint8Array): Uint8Array | null {
  const ptr = binding.lmdb_cursor_seek(cursor as number as Pointer, key, key.length);
  if (ptr === null) {
    throwErr(errBuf[0] as number);
    return null;
  }
  return new Uint8Array(toArrayBuffer(ptr as Pointer, 0, lenBuf[0]));
}