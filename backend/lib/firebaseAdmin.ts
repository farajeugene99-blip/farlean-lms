import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Emulator HANYA aktif jika secara eksplisit diset di environment variables
// (misal saat menjalankan automated test suite lokal).
// Dilarang melakukan auto-fallback ke loopback emulator pada deployment Vercel.
const hasAuthEmulator = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

// Inisialisasi Firebase Admin SDK secara singleton
if (!getApps().length) {
  const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

  const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY;
  const privateKey = rawPrivateKey
    ? rawPrivateKey.replace(/\\n/g, '\n').trim()
    : undefined;
  const clientEmail = process.env.FIREBASE_CLIENT_EMAIL?.trim();

  if (clientEmail && privateKey) {
    // Mode Kredensial Produksi / Preview Vercel
    initializeApp({
      credential: cert({
        projectId,
        clientEmail,
        privateKey,
      }),
    });
  } else {
    // Mode Emulator Lokal atau GCP Metadata Default
    if (!hasFirestoreEmulator && !hasAuthEmulator) {
      console.warn(
        '⚠️ [FirebaseAdmin] Kredensial service account tidak ditemukan dan emulator tidak diset. ' +
          'Menggunakan default project credential.'
      );
    }
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
