import { getApps, initializeApp, cert } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import type { VercelRequest, VercelResponse } from '@vercel/node';

// Pastikan inisialisasi hanya terjadi sekali (singleton)
if (!getApps().length) {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined;

  initializeApp({
    credential: cert({
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: privateKey,
    }),
  });
}

export const db = getFirestore();
export const auth = getAuth();
export { FieldValue };

/**
 * Middleware untuk memverifikasi Authorization: Bearer <ID_TOKEN>
 * dan memastikan email user sudah diverifikasi.
 */
export async function verifyAuth(req: VercelRequest, res: VercelResponse) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Token otentikasi tidak ditemukan.' });
    return null;
  }

  const token = authHeader.split('Bearer ')[1];
  try {
    const decodedToken = await auth.verifyIdToken(token);
    
    // Syarat Blueprint: email wajib diverifikasi sebelum dapat berinteraksi
    if (!decodedToken.email_verified) {
      res.status(403).json({ error: 'Email belum diverifikasi. Silakan cek inbox Anda.' });
      return null;
    }
    
    return decodedToken;
  } catch (error: any) {
    res.status(401).json({ error: 'Sesi kedaluwarsa atau token tidak valid.' });
    return null;
  }
}