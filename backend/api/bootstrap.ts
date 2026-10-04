import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';

// Domain mapping kanonis (Label boundary rules)
const INSTITUTION_DOMAINS: Record<string, 'MAHASISWA' | 'DOSEN'> = {
  'kampus.ac.id': 'MAHASISWA',
  'dosen.kampus.ac.id': 'DOSEN',
  'farlean.edu': 'MAHASISWA',
  'dosen.farlean.edu': 'DOSEN',
};

function resolveAccountType(email?: string): 'MAHASISWA' | 'DOSEN' | 'UMUM' {
  if (!email || !email.includes('@')) return 'UMUM';
  const domain = email.toLowerCase().split('@')[1];
  if (!domain) return 'UMUM';

  // 1. Cek DOSEN terlebih dahulu
  for (const [instDomain, type] of Object.entries(INSTITUTION_DOMAINS)) {
    if (type === 'DOSEN') {
      if (domain === instDomain || domain.endsWith('.' + instDomain)) {
        return 'DOSEN';
      }
    }
  }

  // 2. Cek MAHASISWA
  for (const [instDomain, type] of Object.entries(INSTITUTION_DOMAINS)) {
    if (type === 'MAHASISWA') {
      if (domain === instDomain || domain.endsWith('.' + instDomain)) {
        return 'MAHASISWA';
      }
    }
  }

  return 'UMUM';
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // Verifikasi auth token (mengizinkan token unverified agar dokumen awal dapat dibuat)
  const token = await verifyAuth(req, res, { requireEmailVerified: false });
  if (!token) return;

  const uid = token.uid;
  const email = token.email || '';
  const isVerified = token.email_verified === true;
  const { name, photoUrl } = req.body || {};

  try {
    const userRef = db.collection('users').doc(uid);
    const existingDoc = await userRef.get();

    // Aturan Addendum Farlean LMS:
    // - Jika email belum diverifikasi: simpan 'UMUM'
    // - Jika email sudah terverifikasi: hitung ulang dari domain
    const calculatedAccountType = isVerified ? resolveAccountType(email) : 'UMUM';

    if (!existingDoc.exists) {
      // Pembuatan dokumen awal
      const newUserData = {
        uid,
        name: typeof name === 'string' && name.trim().length > 0 ? name.trim() : email.split('@')[0] || 'Pengguna',
        email,
        account_type: calculatedAccountType,
        role: 'USER', // Seluruh akun baru default role USER
        photo_url: typeof photoUrl === 'string' ? photoUrl : null,
        last_active: FieldValue.serverTimestamp(),
        mfa_enabled: false,
      };

      await userRef.set(newUserData);

      return res.status(200).json({
        success: true,
        isNew: true,
        accountType: calculatedAccountType,
        emailVerified: isVerified,
        message: 'Profil pengguna berhasil diinisialisasi.',
      });
    } else {
      // Dokumen sudah ada: idempoten, pertahankan role yang ada (jangan menimpa GURU/ADMIN)
      const currentData = existingDoc.data() || {};
      const updates: Record<string, any> = {
        last_active: FieldValue.serverTimestamp(),
      };

      // Jika user baru saja verifikasi email, tingkatkan account_type jika sesuai domain
      if (isVerified && currentData.account_type === 'UMUM') {
        const upgradedType = resolveAccountType(email);
        if (upgradedType !== 'UMUM') {
          updates.account_type = upgradedType;
        }
      }

      if (typeof name === 'string' && name.trim().length > 0) {
        updates.name = name.trim();
      }

      await userRef.update(updates);

      return res.status(200).json({
        success: true,
        isNew: false,
        accountType: updates.account_type || currentData.account_type,
        emailVerified: isVerified,
        message: 'Profil pengguna berhasil diperbarui.',
      });
    }
  } catch (error: any) {
    console.error('Error bootstrap user:', error);
    return res.status(500).json({ error: 'Gagal menginisialisasi profil pengguna di server.' });
  }
}
