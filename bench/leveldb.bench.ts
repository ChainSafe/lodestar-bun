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
        leveldb.dbWrite(db, batch);
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
        leveldb.dbWrite(db, batch);
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
        leveldb.dbWrite(db, batch);
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
  }
});
