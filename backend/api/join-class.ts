import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { resolveAccountType } from '../lib/domains';
import { applyCors } from '../lib/cors';

const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_FAILED_ATTEMPTS = 5;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi token pengirim (Wajib email terverifikasi sesuai Blueprint)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const { classCode } = req.body || {};
  if (!classCode || typeof classCode !== 'string') {
    return res.status(400).json({ error: 'Kode kelas wajib diisi.' });
  }

  // 2. Normalisasi & Validasi Format Kode Kelas (A-Z0-9, 6-12 karakter)
  const normalizedCode = classCode.trim().toUpperCase();
  if (normalizedCode.length < 6 || normalizedCode.length > 12) {
    return res.status(400).json({ error: 'Panjang kode kelas harus antara 6 hingga 12 karakter.' });
  }
  if (!/^[A-Z0-9]+$/.test(normalizedCode)) {
    return res.status(400).json({ error: 'Kode kelas hanya boleh mengandung huruf kapital dan angka.' });
  }

  const rateLimitRef = db.collection('rate_limits').doc(user.uid);

  try {
    // 3. Eksekusi Transaksi Atomik: Rate Limit + Lookup Kelas + Membership Check
    const result = await db.runTransaction(async (transaction) => {
      const now = Date.now();

      // A. Cek & Update Rate Limit
      const rateDoc = await transaction.get(rateLimitRef);
      const userDoc = await transaction.get(db.collection('users').doc(user.uid));
      let failedAttempts = 0;
      let windowStart = now;

      if (rateDoc.exists) {
        const rateData = rateDoc.data() || {};
        const lastStart = rateData.window_start?.toMillis ? rateData.window_start.toMillis() : (rateData.window_start || 0);

        if (now - lastStart < RATE_LIMIT_WINDOW_MS) {
          // Masih dalam window 15 menit
          failedAttempts = rateData.failed_attempts || 0;
          windowStart = lastStart;

          if (failedAttempts >= MAX_FAILED_ATTEMPTS) {
            throw { status: 429, message: 'Terlalu banyak percobaan kode kelas yang gagal. Silakan coba 15 menit lagi.' };
          }
        } else {
          // Window telah kedaluwarsa: reset
          failedAttempts = 0;
          windowStart = now;
        }
      }

      // B. Cari kelas berdasarkan kode unik
      const classQuery = await db
        .collection('classes')
        .where('code', '==', normalizedCode)
        .limit(1)
        .get();

      if (classQuery.empty) {
        // Increment counter kegagalan
        transaction.set(
          rateLimitRef,
          {
            failed_attempts: failedAttempts + 1,
            window_start: typeof windowStart === 'number' ? new Date(windowStart) : windowStart,
            last_attempt: FieldValue.serverTimestamp(),
          },
          { merge: true }
        );

        throw { status: 404, message: 'Kelas dengan kode tersebut tidak ditemukan.' };
      }

      const classDoc = classQuery.docs[0];
      const classId = classDoc.id;
      const classData = classDoc.data();

      // B2. Tolak pendaftaran jika kelas berstatus Archived
      if (classData.status === 'Archived') {
        throw { status: 400, message: 'Kelas ini telah diarsipkan dan tidak lagi menerima pendaftaran anggota baru.' };
      }

      // C. Periksa status keanggotaan pengguna saat ini
      const memberRef = db.collection('classes').doc(classId).collection('members').doc(user.uid);
      const existingMember = await transaction.get(memberRef);

      if (existingMember.exists) {
        const memberData = existingMember.data() || {};
        if (memberData.status === 'removed') {
          throw { status: 403, message: 'Anda telah dikeluarkan dari kelas ini dan tidak dapat bergabung kembali secara otomatis.' };
        }
        if (memberData.status === 'active') {
          throw { status: 400, message: 'Anda sudah menjadi anggota aktif di kelas ini.' };
        }
        if (memberData.status === 'pending') {
          return {
            classId,
            className: classData.name || 'Kelas Farlean LMS',
            status: 'pending',
            message: 'Permintaan bergabung Anda masih menunggu persetujuan Guru.',
          };
        }
      }

      // D. Hitung ulang account_type langsung dari email token saat ini
      const calculatedAccountType = resolveAccountType(user.email);
      const newStatus = (calculatedAccountType === 'MAHASISWA' || calculatedAccountType === 'DOSEN')
        ? 'active'
        : 'pending';

      // E. Daftarkan pengguna ke sub-koleksi members dan enrolled_classes pengguna
      const resolvedDisplayName = userDoc.data()?.name || user.email?.split('@')[0] || 'Anggota';
      transaction.set(
        memberRef,
        {
          display_name: resolvedDisplayName,
          account_type: calculatedAccountType,
          status: newStatus,
          joined_at: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      const enrolledRef = db.collection('users').doc(user.uid).collection('enrolled_classes').doc(classId);
      transaction.set(
        enrolledRef,
        {
          class_id: classId,
          status: newStatus,
          joined_at: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      // F. Reset counter kegagalan karena request kode valid
      transaction.set(
        rateLimitRef,
        {
          failed_attempts: 0,
          window_start: new Date(now),
          last_attempt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );

      return {
        classId,
        className: classData.name || 'Kelas Farlean LMS',
        status: newStatus,
        message: newStatus === 'active'
          ? 'Berhasil bergabung ke dalam kelas.'
          : 'Permintaan bergabung berhasil dikirim. Menunggu persetujuan Guru.',
      };
    });

    return res.status(200).json({
      success: true,
      ...result,
    });
  } catch (error: any) {
    if (error && error.status && error.message) {
      return res.status(error.status).json({ error: error.message });
    }
    console.error('Error join-class:', error);
    return res.status(500).json({ error: 'Terjadi kesalahan pada server saat memproses kode kelas.' });
  }
}