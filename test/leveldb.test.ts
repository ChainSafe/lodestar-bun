import {afterEach, beforeEach, describe, expect, test} from "bun:test";
import * as fs from "node:fs";

import * as leveldb from "../src/leveldb.ts";

describe("leveldb", () => {
  let dbPath: string;
  beforeEach(() => {
    dbPath = fs.mkdtempSync("db");
  });
  afterEach(() => {
    fs.rmSync(dbPath, {recursive: true, force: true});
  });

  test("get/set/delete", () => {
    const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

    const key = new Uint8Array([1, 2, 3]);
    const value = new Uint8Array([4, 5, 6]);

    leveldb.dbPut(db, key, value);
    const retrieved = leveldb.dbGet(db, key);
    expect(retrieved).toEqual(value);

    leveldb.dbDelete(db, key);
    const deleted = leveldb.dbGet(db, key);
    expect(deleted).toBeNull();

    leveldb.dbClose(db);
  });

  test("batch write", () => {
    const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

    const batch = [
      {key: new Uint8Array([1]), value: new Uint8Array([10])},
      {key: new Uint8Array([2]), value: new Uint8Array([20])},
      {key: new Uint8Array([3]), value: new Uint8Array([30])},
    ];

    leveldb.dbBatchPut(db, batch);

    for (const {key, value} of batch) {
      const retrieved = leveldb.dbGet(db, key);
      expect(retrieved).toEqual(value);
    }

    leveldb.dbClose(db);
  });

  test("iterator", () => {
    const db = leveldb.dbOpen(dbPath, {create_if_missing: true});
    
    const entries = [
      {key: new Uint8Array([1]), value: new Uint8Array([10])},
      {key: new Uint8Array([2]), value: new Uint8Array([20])},
      {key: new Uint8Array([3]), value: new Uint8Array([30])},
    ];

    for (const {key, value} of entries) {
      leveldb.dbPut(db, key, value);
    }

    const iter = leveldb.dbIterator(db);
    leveldb.iteratorSeekToFirst(iter);

    let index = 0;
    while (leveldb.iteratorValid(iter)) {
      const key = leveldb.iteratorKey(iter);
      const value = leveldb.iteratorValue(iter);
      expect(key).toEqual(entries[index]!.key);
      expect(value).toEqual(entries[index]!.value);
      index++;
      leveldb.iteratorNext(iter);
    }
    expect(index).toBe(entries.length);

    leveldb.iteratorDestroy(iter);
    leveldb.dbClose(db);
  });
});
