"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.grantReward = exports.onRecipeDelete = exports.onRecipeCreate = void 0;
// functions/src/index.ts
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const firestore_2 = require("firebase-functions/v2/firestore");
const REGION = "asia-northeast1"; // ★ここを変更（東京）
admin.initializeApp();
const db = admin.firestore();
const usersRef = (uid) => db.doc(`users/${uid}`);
const rewardEventRef = (uid, id) => db.doc(`rewards/${uid}/events/${id}`);
exports.onRecipeCreate = (0, firestore_2.onDocumentCreated)({ region: REGION, document: "recipes/{uid}/items/{id}" }, async (event) => {
    const uid = event.params.uid;
    await db.runTransaction(async (tx) => {
        const uRef = usersRef(uid);
        const snap = await tx.get(uRef);
        if (!snap.exists) {
            tx.set(uRef, { maxRecipes: 10, recipeCount: 1, createdAt: firestore_1.Timestamp.now(), updatedAt: firestore_1.Timestamp.now() });
        }
        else {
            tx.update(uRef, { recipeCount: firestore_1.FieldValue.increment(1), updatedAt: firestore_1.Timestamp.now() });
        }
    });
});
exports.onRecipeDelete = (0, firestore_2.onDocumentDeleted)({ region: REGION, document: "recipes/{uid}/items/{id}" }, async (event) => {
    const uid = event.params.uid;
    await db.runTransaction(async (tx) => {
        const uRef = usersRef(uid);
        const snap = await tx.get(uRef);
        const cur = (snap.exists ? snap.data()?.recipeCount : 0) ?? 0;
        const next = Math.max(0, Number(cur) - 1);
        if (!snap.exists) {
            tx.set(uRef, { maxRecipes: 10, recipeCount: next, createdAt: firestore_1.Timestamp.now(), updatedAt: firestore_1.Timestamp.now() });
        }
        else {
            tx.update(uRef, { recipeCount: next, updatedAt: firestore_1.Timestamp.now() });
        }
    });
});
exports.grantReward = (0, https_1.onCall)({ region: REGION }, async (req) => {
    if (!req.auth)
        throw new https_1.HttpsError("unauthenticated", "Sign-in required");
    const uid = req.auth.uid;
    const amount = Number(req.data?.amount ?? 5);
    const eventId = String(req.data?.eventId ?? `manual-${Date.now()}`);
    if (!Number.isFinite(amount) || amount <= 0 || amount > 50) {
        throw new https_1.HttpsError("invalid-argument", "amount out of range");
    }
    return await db.runTransaction(async (tx) => {
        const evRef = rewardEventRef(uid, eventId);
        const evSnap = await tx.get(evRef);
        if (evSnap.exists)
            return { status: "duplicate", amount };
        const uRef = usersRef(uid);
        const uSnap = await tx.get(uRef);
        if (!uSnap.exists) {
            tx.set(uRef, { maxRecipes: amount, recipeCount: 0, createdAt: firestore_1.Timestamp.now(), updatedAt: firestore_1.Timestamp.now() });
        }
        else {
            tx.update(uRef, { maxRecipes: firestore_1.FieldValue.increment(amount), updatedAt: firestore_1.Timestamp.now() });
        }
        tx.set(evRef, { amount, createdAt: firestore_1.Timestamp.now() });
        return { status: "applied", amount };
    });
});
