import {describe, bench, beforeAll, afterAll} from "@chainsafe/benchmark";
import * as fs from "node:fs";
import * as leveldb from "../src/leveldb.ts";
import { intToBytes } from "../src/bytes.ts";

describe("leveldb", () => {
  let dbPath: string;
  let db: leveldb.DB;
  beforeAll(() => {
    dbPath = fs.mkdtempSync("db");
    db = leveldb.dbOpen(dbPath, {create_if_missing: true});
  });
  afterAll(() => {
    leveldb.dbClose(db);
    fs.rmSync(dbPath, {recursive: true, force: true});
  });


  for (const n of [1, 10, 100, 1000, 10000]) {
    bench({
      id: `set ${n} entries`,
      beforeEach: () => new Uint8Array(1000),
      fn: (val) => {
        for (let i = 0; i < n; i++) {
          leveldb.dbPut(db, intToBytes(i, 4, "le"), val);
        }
      },
    });

    bench({
      id: `batch set ${n} entries`,
      beforeEach: () => new Uint8Array(1000),
      fn: (val) => {
        const batch = [];
        for (let i = 0; i < n; i++) {
          batch.push({key: intToBytes(i, 4, "le"), value: val});
        }
        leveldb.dbBatchPut(db, batch);
      },
    });

    bench({
      id: `get ${n} entries`,
      before: () => {
        const val = new Uint8Array(1000);
        const batch = [];
        for (let i = 0; i < n; i++) {
          batch.push({key: intToBytes(i, 4, "le"), value: val});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: () => {
        for (let i = 0; i < n; i++) {
          leveldb.dbGet(db, intToBytes(i, 4, "le"));
        }
      },
    });

    bench({
      id: `iterate ${n} entries`,
      before: () => {
        const val = new Uint8Array(1000);
        const batch = [];
        for (let i = 0; i < n; i++) {
          batch.push({key: intToBytes(i, 4, "le"), value: val});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: () => {
        const iter = leveldb.dbIterator(db);
        leveldb.iteratorSeekToFirst(iter);
        for (let i = 0; i < n; i++) {
          leveldb.iteratorKey(iter);
          leveldb.iteratorNext(iter);
        }
        leveldb.iteratorDestroy(iter);
      },
    });

    bench({
      id: `get many via sync get for ${n} entries`,
      before: () => {
        const value = new Uint8Array(1000);
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        const batch = [];
        for (const key of keys) {
          batch.push({key, value});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: () => {
        const result = [];
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        for (const key of keys) {
          result.push(leveldb.dbGet(db, key));
        }
      },
    });

    bench({
      id: `get many via async get for ${n} entries`,
      before: () => {
        const value = new Uint8Array(1000);
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        const batch = [];
        for (const key of keys) {
          batch.push({key, value});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: async () => {
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        await Promise.all(keys.map(k => leveldb.dbGet(db, k)));
      },
    });

    bench({
      id: `get many via native getMany for ${n} entries`,
      before: () => {
        const value = new Uint8Array(1000);
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        const batch = [];
        for (const key of keys) {
          batch.push({key, value});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: () => {
        const keys = Array.from({length: n}, (_, i) => intToBytes(i, 4, "le"));
        leveldb.dbGetMany(db, keys);
      },
    });

    bench({
      id: `get many via async get for ${n} entries with larger key/value sizes`,
      before: () => {
        const valueSize = 8 * 1024; // 8kb
        const keySize = 128; // 128b

        const value = new Uint8Array(valueSize);
        const keys = Array.from({length: n}, (_, i) => encodeLargeKey(i, keySize));

        const batch = [];
        for (const key of keys) {
          batch.push({key, value});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: async () => {
        const keySize = 128; // 128b

        const keys = Array.from({length: n}, (_, i) => encodeLargeKey(i, keySize));
        await Promise.all(keys.map(k => leveldb.dbGet(db, k)));
      },
    });

    bench({
      id: `get many via native getMany for ${n} entries with larger key/value sizes`,
      before: () => {
        const valueSize = 8 * 1024; // 8kb
        const keySize = 128; // 128b

        const value = new Uint8Array(valueSize);
        const keys = Array.from({length: n}, (_, i) => encodeLargeKey(i, keySize));

        const batch = [];
        for (const key of keys) {
          batch.push({key, value});
        }
        leveldb.dbBatchPut(db, batch);
      },
      fn: () => {
        const keySize = 128; // 128b
        
        const keys = Array.from({length: n}, (_, i) => encodeLargeKey(i, keySize));
        leveldb.dbGetMany(db, keys);
      },
    });
  }
});

function encodeLargeKey(i: number, size: number): Uint8Array {
  const chunks = size / 8;
  return Buffer.concat(Array.from({length: chunks}, (_, chunkIndex) => intToBytes(i+chunkIndex, 8, "le")));
}