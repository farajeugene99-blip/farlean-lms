import type { VercelRequest, VercelResponse } from '@vercel/node';
import crypto from 'crypto';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';

function generateRandomCode(): string {
  // Menghasilkan 8 karakter alfanumerik huruf kapital yang mudah dibaca
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let result = '';
  const bytes = crypto.randomBytes(8);
  for (let i = 0; i < 8; i++) {
    result += chars[bytes[i] % chars.length];
  }
  return result;
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Auth
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 2. Verifikasi Wewenang: Hanya GURU atau ADMIN yang boleh membuat kelas
  const role = (user as any).role || 'USER';
  if (role !== 'GURU' && role !== 'ADMIN') {
    return res.status(403).json({
      error: 'Akses ditolak: Hanya Pengajar (Guru) atau Admin yang berhak membuat kelas baru.',
    });
  }

  const { name, description = '', customCode } = req.body || {};

  // 3. Validasi Nama Kelas
  if (!name || typeof name !== 'string' || name.trim().length < 3 || name.trim().length > 100) {
    return res.status(400).json({
      error: 'Nama kelas wajib diisi dan memiliki panjang antara 3 hingga 100 karakter.',
    });
  }

  // 4. Validasi atau Pembuatan Kode Kelas
  let finalCode = '';
  if (customCode && typeof customCode === 'string') {
    finalCode = customCode.trim().toUpperCase();
    if (finalCode.length < 6 || finalCode.length > 12 || !/^[A-Z0-9]+$/.test(finalCode)) {
      return res.status(400).json({
        error: 'Kode kelas khusus harus berupa 6-12 karakter alfanumerik kapital.',
      });
    }
  } else {
    finalCode = generateRandomCode();
  }

  try {
    // 5. Eksekusi Transaksi Atomik: Cek Keunikan Kode + Buat Dokumen Kelas & Mapping Kode
    const result = await db.runTransaction(async (transaction) => {
      const codeRef = db.collection('class_codes').doc(finalCode);
      const codeDoc = await transaction.get(codeRef);

      if (codeDoc.exists) {
        throw {
          status: 409,
          message: 'Kode kelas tersebut sudah digunakan. Silakan gunakan kode lain atau biarkan sistem membuatkan kode acak.',
        };
      }

      // Ambil display name dosen
      const userDoc = await transaction.get(db.collection('users').doc(user.uid));
      const teacherName = userDoc.data()?.name || user.email?.split('@')[0] || 'Dosen Pengajar';

      const classRef = db.collection('classes').doc();
      const newClassId = classRef.id;

      // Buat dokumen classes
      transaction.set(classRef, {
        name: name.trim(),
        code: finalCode,
        description: typeof description === 'string' ? description.trim() : '',
        teacher_id: user.uid,
        status: 'Active',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      // Buat mapping di class_codes (menjamin keunikan global)
      transaction.set(codeRef, {
        class_id: newClassId,
        created_at: FieldValue.serverTimestamp(),
      });

      // Daftarkan dosen sebagai member aktif pengelola
      const memberRef = classRef.collection('members').doc(user.uid);
      transaction.set(memberRef, {
        display_name: teacherName,
        account_type: 'DOSEN',
        status: 'active',
        joined_at: FieldValue.serverTimestamp(),
      });

      // Daftarkan kelas di daftar kelas milik dosen
      const enrolledRef = db.collection('users').doc(user.uid).collection('enrolled_classes').doc(newClassId);
      transaction.set(enrolledRef, {
        class_id: newClassId,
        status: 'active',
        joined_at: FieldValue.serverTimestamp(),
      });

      return {
        classId: newClassId,
        code: finalCode,
        name: name.trim(),
        teacherId: user.uid,
      };
    });

    return res.status(201).json({
      success: true,
      ...result,
    });
  } catch (err: any) {
    if (err && err.status && err.message) {
      return res.status(err.status).json({ error: err.message });
    }
    console.error('Error create-class:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan pada server saat membuat kelas.' });
  }
}
