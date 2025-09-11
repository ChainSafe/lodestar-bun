import {describe, bench, beforeAll, afterAll} from "@chainsafe/benchmark";
import * as fs from "node:fs";
import * as lmdb from "../src/lmdb.ts";
import { intToBytes } from "../src/bytes.ts";

describe("lmdb", () => {
  let dbPath: string;
  let env: lmdb.Environment;
  beforeAll(() => {
    dbPath = fs.mkdtempSync("db");
    env = lmdb.environmentInit(dbPath);
  });
  afterAll(() => {
    lmdb.environmentDeinit(env);
    fs.rmSync(dbPath, {recursive: true, force: true});
  });

  bench({
    id: "set 10k entries",
    beforeEach: () => new Uint8Array(1000),
    fn: (val) => {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      for (let i = 0; i < 10000; i++) {
        lmdb.databaseSet(txn, db, intToBytes(i, 4, "le"), val);
      }
      lmdb.transactionCommit(txn);
    },
  });

  bench({
    id: "get 10k entries",
    before: () => {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      const val = new Uint8Array(1000);
      for (let i = 0; i < 10000; i++) {
        lmdb.databaseSet(txn, db, intToBytes(i, 4, "le"), val);
      }
      lmdb.transactionCommit(txn);
    },
    fn: () => {
      const txn = lmdb.transactionBegin(env, true);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      for (let i = 0; i < 10000; i++) {
        lmdb.databaseGet(txn, db, intToBytes(i, 4, "le"));
      }
      lmdb.transactionCommit(txn);
    },
  });

  bench({
    id: "iterate 10k entries",
    before: () => {
      const txn = lmdb.transactionBegin(env, false);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      const val = new Uint8Array(1000);
      for (let i = 0; i < 10000; i++) {
        lmdb.databaseSet(txn, db, intToBytes(i, 4, "le"), val);
      }
      lmdb.transactionCommit(txn);
    },
    fn: () => {
      const txn = lmdb.transactionBegin(env, true);
      const db = lmdb.databaseOpen(txn, "testdb", {create: true});
      const cursor = lmdb.databaseCursor(txn, db);
      for (let i = 0; i < 10000; i++) {
        lmdb.cursorGoToNext(cursor)!;
      }
      lmdb.cursorDeinit(cursor);
      lmdb.transactionCommit(txn);
    },
  });
});
