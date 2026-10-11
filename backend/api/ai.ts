import type { VercelRequest, VercelResponse } from '@vercel/node';
import { verifyAuth } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  // Proteksi Endpoint AI: Wajib terautentikasi dan email terverifikasi
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // Kunci permukaan serangan: Endpoint belum dibuka untuk umum sebelum Phase 3
  return res.status(503).json({
    status: 'AI endpoint placeholder',
    message: 'Fitur AI Assistant saat ini masih dalam tahap pengembangan (Phase 3).',
  });
}
