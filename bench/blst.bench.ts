import { describe, bench } from "@chainsafe/benchmark";

import * as blst from "../src/blst.ts";
import * as other from "@chainsafe/blst";

describe("blst", () => {
  const ikm = new Uint8Array(32);
  //  bench("blst - keygen", () => {
  //    blst.SecretKey.fromKeygen(ikm);
  //  });
  //  bench("other - keygen", () => {
  //    other.SecretKey.fromKeygen(ikm);
  //  });
  //
  //  bench({
  //    id: "blst - sign",
  //    beforeEach: () => {
  //      const sk = blst.SecretKey.fromKeygen(ikm);
  //      return { sk, msg: new Uint8Array(32) };
  //    },
  //    fn: ({ sk, msg }) => {
  //      sk.sign(msg);
  //    },
  //  });
  //  bench({
  //    id: "other - sign",
  //    beforeEach: () => {
  //      const sk = other.SecretKey.fromKeygen(ikm);
  //      return { sk, msg: new Uint8Array(32) };
  //    },
  //    fn: ({ sk, msg }) => {
  //      sk.sign(msg);
  //    },
  //  });
  //
  //  bench({
  //    id: "blst - verify",
  //    beforeEach: () => {
  //      const sk = blst.SecretKey.fromKeygen(ikm);
  //      const pk = sk.toPublicKey();
  //      const msg = new Uint8Array(32);
  //      const sig = sk.sign(msg);
  //      return { pk, msg, sig };
  //    },
  //    fn: ({ pk, msg, sig }) => {
  //      sig.verify(msg, pk, true, true);
  //    },
  //  });
  //  bench({
  //    id: "other - verify",
  //    beforeEach: () => {
  //      const sk = other.SecretKey.fromKeygen(ikm);
  //      const pk = sk.toPublicKey();
  //      const msg = new Uint8Array(32);
  //      const sig = sk.sign(msg);
  //      return { pk, msg, sig };
  //    },
  //    fn: ({ pk, msg, sig }) => {
  //      other.verify(msg, pk, sig, true, true);
  //    },
  //  });

  bench({
    id: "blst - aggregateVerify 1",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 1; i++) {
        const sk = blst.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = blst.aggregateSignatures(sigs, true);
      blst.init();
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      aggSig.aggregateVerify(msgs, pks, true, true);
    },
  });
  bench({
    id: "other - aggregateVerify 1",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 1; i++) {
        const sk = other.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = other.aggregateSignatures(sigs, true);
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      other.aggregateVerify(msgs, pks, aggSig, true, true);
    },
  });

  bench({
    id: "blst - aggregateVerify 16",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 16; i++) {
        const sk = blst.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = blst.aggregateSignatures(sigs, true);
      blst.init();
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      aggSig.aggregateVerify(msgs, pks, true, true);
    },
  });
  bench({
    id: "other - aggregateVerify 16",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 16; i++) {
        const sk = other.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = other.aggregateSignatures(sigs, true);
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      other.aggregateVerify(msgs, pks, aggSig, true, true);
    },
  });

  bench({
    id: "blst - aggregateVerify 32",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 32; i++) {
        const sk = blst.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = blst.aggregateSignatures(sigs, true);
      blst.init();
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      aggSig.aggregateVerify(msgs, pks, true, true);
    },
  });
  bench({
    id: "other - aggregateVerify 32",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 32; i++) {
        const sk = other.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = other.aggregateSignatures(sigs, true);
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      other.aggregateVerify(msgs, pks, aggSig, true, true);
    },
  });

  bench({
    id: "blst - aggregateVerify 128",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 128; i++) {
        const sk = blst.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = blst.aggregateSignatures(sigs, true);
      blst.init();
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      aggSig.aggregateVerify(msgs, pks, true, true);
    },
  });
  bench({
    id: "other - aggregateVerify 128",
    beforeEach: () => {
      const sks = [];
      const pks = [];
      const sigs = [];
      const msgs = [];
      for (let i = 0; i < 128; i++) {
        const sk = other.SecretKey.fromKeygen(ikm);
        sks.push(sk);
        pks.push(sk.toPublicKey());
        const msg = new Uint8Array(32);
        msgs.push(msg);
        sigs.push(sk.sign(msg));
      }
      const aggSig = other.aggregateSignatures(sigs, true);
      return { pks, msgs, aggSig };
    },
    fn: ({ pks, msgs, aggSig }) => {
      other.aggregateVerify(msgs, pks, aggSig, true, true);
    },
  });


});

