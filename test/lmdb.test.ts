import {afterEach, beforeEach, describe, expect, test} from "bun:test";
import * as fs from "node:fs";

import * as lmdb from "../src/lmdb.ts";

describe("lmdb", () => {
  let dbPath: string;
  beforeEach(() => {
    dbPath = fs.mkdtempSync("db");
  });
  afterEach(() => {
    fs.rmSync(dbPath, {recursive: true, force: true});
  });

  test("get - empty db", () => {
    const env = lmdb.environmentInit(dbPath);
    const txn = lmdb.transactionBegin(env, false);
    const db = lmdb.databaseOpen(txn, "testdb", {create: true});

    const key = new Uint8Array([1, 2, 3]);

    {
      const retrieved = lmdb.databaseGet(txn, db, key);
      expect(retrieved).toBeNull();
    }
    {
      const cursor = lmdb.databaseCursor(txn, db);
      const retrieved = lmdb.cursorGoToFirst(cursor);
      expect(retrieved).toBeNull();
      lmdb.cursorDeinit(cursor);
    }

    lmdb.transactionCommit(txn);
    lmdb.environmentDeinit(env);
  });

  test("get/set/delete", () => {
    const env = lmdb.environmentInit(dbPath);
    const txn = lmdb.transactionBegin(env, false);
    const db = lmdb.databaseOpen(txn, "testdb", {create: true});

    const key = new Uint8Array([1, 2, 3]);
    const value = new Uint8Array([4, 5, 6]);

    lmdb.databaseSet(txn, db, key, value);
    const retrieved = lmdb.databaseGet(txn, db, key);
    expect(retrieved).toEqual(value);

    lmdb.databaseDelete(txn, db, key);
    const deleted = lmdb.databaseGet(txn, db, key);
    expect(deleted).toBeNull();

    lmdb.transactionCommit(txn);
    lmdb.environmentDeinit(env);
  });

  test("value after commit", () => {
    let retrieved: Uint8Array | null;
    const key = new Uint8Array([1, 2, 3]);
    const value = new Uint8Array([4, 5, 6]);
    {
      const env = lmdb.environmentInit(dbPath);
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});


      lmdb.databaseSet(txn, db, key, value);
      retrieved = lmdb.databaseGet(txn, db, key);
      expect(retrieved).toEqual(value);

      lmdb.databaseDelete(txn, db, key);
      const deleted = lmdb.databaseGet(txn, db, key);
      expect(deleted).toBeNull();

      lmdb.transactionCommit(txn);
      lmdb.environmentDeinit(env);
    }
    {
      const env = lmdb.environmentInit(dbPath);
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});


      lmdb.databaseSet(txn, db, key, new Uint8Array([7, 8, 9]));
      lmdb.databaseDelete(txn, db, key);
      const deleted = lmdb.databaseGet(txn, db, key);
      expect(deleted).toBeNull();

      lmdb.transactionCommit(txn);
      lmdb.environmentDeinit(env);
    }
    // The value will NOT still be valid after the transaction is committed or subsequent update.
    expect(retrieved).not.toEqual(value);
  });

  test("transaction commit", () => {
    const env = lmdb.environmentInit(dbPath);
    const key = new Uint8Array([1, 2, 3]);
      const value = new Uint8Array([4, 5, 6]);
    {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});

      lmdb.databaseSet(txn, db, key, value);
      lmdb.transactionCommit(txn);
    }

    const txn = lmdb.transactionBegin(env, true);
    const db = lmdb.databaseOpen(txn, "testdb");
    const retrieved = lmdb.databaseGet(txn, db, key);
    expect(retrieved).toEqual(value);
    lmdb.transactionCommit(txn);

    lmdb.environmentDeinit(env);
  });

  test("transaction abort", () => {
    const env = lmdb.environmentInit(dbPath);
    const key = new Uint8Array([1, 2, 3]);
    const value = new Uint8Array([4, 5, 6]);
    {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});

      lmdb.databaseSet(txn, db, key, value);
      lmdb.transactionAbort(txn);
    }

    const txn = lmdb.transactionBegin(env, true);
    expect(() => lmdb.databaseOpen(txn, "testdb")).toThrow();
    lmdb.transactionCommit(txn);

    lmdb.environmentDeinit(env);
  });

  test("cursor behavior", () => {
    const env = lmdb.environmentInit(dbPath);
    const key = (n: number) => new Uint8Array([n]);
    const value = (n: number) => new Uint8Array([n]);

    {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      for (let i = 0; i < 10; i++) {
        lmdb.databaseSet(txn, db, key(i), value(i));
      }
      lmdb.transactionCommit(txn);
    }

    {
      const txn = lmdb.transactionBegin(env, true);
      const db = lmdb.databaseOpen(txn, "testdb");
      const cursor = lmdb.databaseCursor(txn, db);
      
      for (let i = 0; i < 10; i++) {
        const val = lmdb.cursorGoToNext(cursor);
        expect(val).toEqual(key(i));
      }
      lmdb.cursorDeinit(cursor);
      lmdb.transactionCommit(txn);
    }

    {
      const txn = lmdb.transactionBegin(env, true);
      const db = lmdb.databaseOpen(txn, "testdb");
      const cursor = lmdb.databaseCursor(txn, db);
      
      const k = lmdb.cursorGoToLast(cursor);
      expect(k).toEqual(key(9));
      for (let i = 8; i >= 0; i--) {
        const val = lmdb.cursorGoToPrevious(cursor);
        expect(val).toEqual(key(i));
      }
      lmdb.cursorDeinit(cursor);
      lmdb.transactionCommit(txn);
    }
    lmdb.environmentDeinit(env);
  });
});
