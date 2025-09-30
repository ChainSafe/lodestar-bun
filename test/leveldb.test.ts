import {afterEach, beforeEach, describe, expect, test} from "bun:test";
import * as fs from "node:fs";

import * as leveldb from "../src/leveldb.ts";
import path from "node:path";

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
    const value = new Uint8Array(Array.from({length: 256}, (_, i) => i));

    leveldb.dbPut(db, key, value);
    const retrieved = leveldb.dbGet(db, key);
    expect(retrieved).toEqual(value);

    leveldb.dbDelete(db, key);
    const deleted = leveldb.dbGet(db, key);
    expect(deleted).toBeNull();

    leveldb.dbClose(db);
  });

  describe("getMany", () => {
    test("get many existing", async () => {
      const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

      const key1 = new Uint8Array([1, 2, 3]);
      const value1 = new Uint8Array(Array.from({length: 256}, () => 1));
      const key2 = new Uint8Array([4, 5, 6]);
      const value2 = new Uint8Array(Array.from({length: 256}, () => 2));

      leveldb.dbPut(db, key1, value1);
      leveldb.dbPut(db, key2, value2);

      const results = leveldb.dbGetMany(db, [key1, key2]);

      expect(results).toEqual([value1, value2]);

      leveldb.dbClose(db);
    });

    test("get many missing", async () => {
      const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

      const key1 = new Uint8Array([1, 2, 3]);
      const value1 = new Uint8Array(Array.from({length: 256}, () => 1));;
      const key2 = new Uint8Array([4, 5, 6]);
      const key3 = new Uint8Array([7, 8, 9]);
      const value3 = new Uint8Array(Array.from({length: 256}, () => 2));

      leveldb.dbPut(db, key1, value1);
      leveldb.dbPut(db, key3, value3);

      const results = leveldb.dbGetMany(db, [key1, key2, key3]);

      expect(results).toEqual([value1, null, value3]);

      leveldb.dbClose(db);
    });

    test("get many all missing", async () => {
      const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

      const key1 = new Uint8Array([1, 2, 3]);
      const key2 = new Uint8Array([4, 5, 6]);

      const results = leveldb.dbGetMany(db, [key1, key2]);

      expect(results).toEqual([null, null]);

      leveldb.dbClose(db);
    });

    test("get many large data set", async () => {
      const db = leveldb.dbOpen(dbPath, {create_if_missing: true});
      const numOfKeys = 300;
      const singleValueSize = 256;

      const data = Array.from({length: numOfKeys}, (_, i) => ({key: new Uint8Array([i, i, i, i]), value: new Uint8Array(Array.from({length: singleValueSize}, () => i))}));
      const keys = data.map(d => d.key);
      const values = data.map(d => d.value);

      for(const {key, value} of data) {
        leveldb.dbPut(db, key, value);
      }

      const results = leveldb.dbGetMany(db, keys);

      expect(results).toEqual(values);

      leveldb.dbClose(db);
    });
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

  test("get many", () => {
    const db = leveldb.dbOpen(dbPath, {create_if_missing: true});

    const keyLength = 32;
    const valueMinLength = 10000;
    const valueMaxLength = 20000;
    const numEntries = 1000;

    const keys = Array.from({length: numEntries}, () => {
      const key = new Uint8Array(keyLength);
      crypto.getRandomValues(key);
      return key;
    });

    const entries = keys.map((key) => {
      const valueLength = Math.floor(Math.random() * (valueMaxLength - valueMinLength + 1)) + valueMinLength;
      const value = new Uint8Array(valueLength);
      crypto.getRandomValues(value);
      return {key, value};
    });

    for (const {key, value} of entries) {
      leveldb.dbPut(db, key, value.slice());
    }

    for (let i = 0; i < numEntries; i ++) {
      const {key, value} = entries[i]!;
      const retrieved = leveldb.dbGet(db, key);
      expect(retrieved).toEqual(value);
    }

    leveldb.dbClose(db);
  });

  test("destroy", () => {
    const db = leveldb.dbOpen(dbPath, {create_if_missing: true});
    leveldb.dbClose(db);
    leveldb.dbDestroy(dbPath);
    expect(fs.existsSync(dbPath)).toBe(false);
  });

  test("destroy non-existent db", () => {
    const nonExistentPath = path.join(dbPath, "non-existent");
    expect(fs.existsSync(nonExistentPath)).toBe(false);
    expect(() => leveldb.dbDestroy(nonExistentPath)).not.toThrow();
  });
});
