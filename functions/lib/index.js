"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.grantReward = exports.onRecipeDelete = exports.onRecipeCreate = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// 追加→ recipeCount++
exports.onRecipeCreate = functions.firestore
    .document("recipes/{uid}/items/{id}")
    .onCreate(async (_, ctx) => {
    const uid = ctx.params.uid;
    await db.doc(`users/${uid}`).update({
        recipeCount: admin.firestore.FieldValue.increment(1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
// 削除→ recipeCount--
exports.onRecipeDelete = functions.firestore
    .document("recipes/{uid}/items/{id}")
    .onDelete(async (_, ctx) => {
    const uid = ctx.params.uid;
    await db.doc(`users/${uid}`).update({
        recipeCount: admin.firestore.FieldValue.increment(-1),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
});
// 広告視聴の報酬付与（冪等性は後ほど詰める）
exports.grantReward = functions.https.onCall(async (data, ctx) => {
    if (!ctx.auth)
        throw new functions.https.HttpsError("unauthenticated", "Sign in required");
    const uid = ctx.auth.uid;
    const amount = Number(data?.amount ?? 5);
    if (amount <= 0)
        throw new functions.https.HttpsError("invalid-argument", "amount must be > 0");
    await db.doc(`users/${uid}`).update({
        maxRecipes: admin.firestore.FieldValue.increment(amount),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    return { status: "applied", amount };
});
