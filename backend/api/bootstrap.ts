import type { VercelRequest, VercelResponse } from '@vercel/node';
import { verifyAuth } from '../lib/firebaseAdmin';
import { bootstrapUser } from '../lib/bootstrapUser';
import { applyCors } from '../lib/cors';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // Verifikasi auth token (mengizinkan token unverified agar dokumen awal dapat dibuat)
  const token = await verifyAuth(req, res, { requireEmailVerified: false });
  if (!token) return;

  const { name, photoUrl } = req.body || {};

  try {
    const result = await bootstrapUser({
      uid: token.uid,
      email: token.email || '',
      emailVerified: token.email_verified === true,
      name,
      photoUrl,
    });

    return res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error: any) {
    console.error('Error bootstrap user:', error);
    return res.status(500).json({ error: 'Gagal menginisialisasi profil pengguna di server.' });
  }
}
