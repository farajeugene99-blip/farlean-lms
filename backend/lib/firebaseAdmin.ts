import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Emulator Safety Guard (Blueprint Phase 1 Rule)
const isProduction =
  process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production';
const allowLiveProd = process.env.ALLOW_PRODUCTION_MODE === 'true';

// Auto-fallback ke emulator lokal jika berada di environment dev/test
if (!isProduction && !allowLiveProd) {
  if (!process.env.FIRESTORE_EMULATOR_HOST) {
    process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
  }
  if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
    process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
  }
  if (!process.env.FIREBASE_PROJECT_ID) {
    process.env.FIREBASE_PROJECT_ID = 'farlean-lms';
  }
}

const hasAuthEmulator = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

// Pastikan inisialisasi hanya terjadi sekali (singleton)
if (!getApps().length) {
  const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

  if (!isProduction && !allowLiveProd && (!hasAuthEmulator || !hasFirestoreEmulator)) {
    console.warn(
      '⚠️ [Backend Safety Guard] Emulator host tidak terdeteksi di mode development/test. ' +
        'Pastikan FIREBASE_AUTH_EMULATOR_HOST dan FIRESTORE_EMULATOR_HOST telah diset, ' +
        'atau gunakan ALLOW_PRODUCTION_MODE=true jika memang disengaja.'
    );
  }

  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined;

  if (process.env.FIREBASE_CLIENT_EMAIL && privateKey) {
    initializeApp({
      credential: cert({
        projectId,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey,
      }),
    });
  } else {
    // Mode emulator lokal / GCP metadata default
    initializeApp({ projectId });
  }
}

export const db = getFirestore();
export const auth = getAuth();
export { FieldValue };

export interface VerifyAuthOptions {
  requireEmailVerified?: boolean;
}

export type TokenVerifier = (token: string) => Promise<any>;
let tokenVerifier: TokenVerifier = (token: string) => auth.verifyIdToken(token);

export function setTokenVerifier(verifier: TokenVerifier) {
  tokenVerifier = verifier;
}

export function resetTokenVerifier() {
  tokenVerifier = (token: string) => auth.verifyIdToken(token);
}

/**
 * Middleware untuk memverifikasi Authorization: Bearer <ID_TOKEN>
 * Default: mewajibkan email_verified == true (sesuai Blueprint Farlean LMS)
 */
export async function verifyAuth(
  req: VercelRequest,
  res: VercelResponse,
  options: VerifyAuthOptions = { requireEmailVerified: true }
) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token otentikasi tidak ditemukan.' });
    return null;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await tokenVerifier(token);

    // Syarat Blueprint: jika requireEmailVerified aktif, email wajib terverifikasi
    if (options.requireEmailVerified && !decodedToken.email_verified) {
      res.status(403).json({ error: 'Email belum diverifikasi. Silakan cek inbox Anda.' });
      return null;
    }

    return decodedToken;
  } catch (error: any) {
    res.status(401).json({ error: 'Sesi kedaluwarsa atau token tidak valid.' });
    return null;
  }
}
