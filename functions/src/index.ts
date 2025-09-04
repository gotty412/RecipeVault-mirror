// functions/src/index.ts
import * as admin from "firebase-admin";
import { FieldValue, Timestamp } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";
import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";

const REGION = "asia-northeast1"; // ★ここを変更（東京）

admin.initializeApp();
const db = admin.firestore();

const usersRef = (uid: string) => db.doc(`users/${uid}`);
const rewardEventRef = (uid: string, id: string) => db.doc(`rewards/${uid}/events/${id}`);

export const onRecipeCreate = onDocumentCreated(
  { region: REGION, document: "recipes/{uid}/items/{id}" },
  async (event) => {
    const uid = event.params.uid as string;
    await db.runTransaction(async (tx) => {
      const uRef = usersRef(uid);
      const snap = await tx.get(uRef);
      if (!snap.exists) {
        tx.set(uRef, { maxRecipes: 10, recipeCount: 1, createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
      } else {
        tx.update(uRef, { recipeCount: FieldValue.increment(1), updatedAt: Timestamp.now() });
      }
    });
  }
);

export const onRecipeDelete = onDocumentDeleted(
  { region: REGION, document: "recipes/{uid}/items/{id}" },
  async (event) => {
    const uid = event.params.uid as string;
    await db.runTransaction(async (tx) => {
      const uRef = usersRef(uid);
      const snap = await tx.get(uRef);
      const cur = (snap.exists ? snap.data()?.recipeCount : 0) ?? 0;
      const next = Math.max(0, Number(cur) - 1);
      if (!snap.exists) {
        tx.set(uRef, { maxRecipes: 10, recipeCount: next, createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
      } else {
        tx.update(uRef, { recipeCount: next, updatedAt: Timestamp.now() });
      }
    });
  }
);

export const grantReward = onCall({ region: REGION }, async (req) => {
  if (!req.auth) throw new HttpsError("unauthenticated", "Sign-in required");
  const uid = req.auth.uid;
  const amount = Number(req.data?.amount ?? 5);
  const eventId = String(req.data?.eventId ?? `manual-${Date.now()}`);
  if (!Number.isFinite(amount) || amount <= 0 || amount > 50) {
    throw new HttpsError("invalid-argument", "amount out of range");
  }
  return await db.runTransaction(async (tx) => {
    const evRef = rewardEventRef(uid, eventId);
    const evSnap = await tx.get(evRef);
    if (evSnap.exists) return { status: "duplicate", amount };
    const uRef = usersRef(uid);
    const uSnap = await tx.get(uRef);
    if (!uSnap.exists) {
      tx.set(uRef, { maxRecipes: amount, recipeCount: 0, createdAt: Timestamp.now(), updatedAt: Timestamp.now() });
    } else {
      tx.update(uRef, { maxRecipes: FieldValue.increment(amount), updatedAt: Timestamp.now() });
    }
    tx.set(evRef, { amount, createdAt: Timestamp.now() });
    return { status: "applied", amount };
  });
});
