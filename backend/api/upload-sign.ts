import type { VercelRequest, VercelResponse } from '@vercel/node';
import { v2 as cloudinary } from 'cloudinary';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_SIGN_ATTEMPTS = 10;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi token pengirim (Wajib email terverifikasi)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 2. Proteksi Wewenang:
  // - GURU dan ADMIN boleh mengunggah materi/manual_books/gambar kelas
  // - USER (Mahasiswa) HANYA boleh meminta signature jika folderType === 'assignments'
  const role = (user as any).role || 'USER';
  const { classId, folderType, assignmentId } = req.body || {};

  if (!classId || typeof classId !== 'string') {
    return res.status(400).json({ error: 'classId wajib diisi.' });
  }

  const cleanClassId = classId.trim();

  if (folderType === 'assignments') {
    if (!assignmentId || typeof assignmentId !== 'string' || assignmentId.trim().length === 0) {
      return res.status(400).json({ error: 'assignmentId wajib diisi untuk folderType assignments.' });
    }
    const cleanAssignmentId = assignmentId.trim();

    // Verifikasi keanggotaan kelas bagi mahasiswa biasa (Admin & Dosen pemilik bebas)
    if (role !== 'ADMIN') {
      const memberDoc = await db.collection('classes').doc(cleanClassId).collection('members').doc(user.uid).get();
      const isTeacher = (await db.collection('classes').doc(cleanClassId).get()).data()?.teacher_id === user.uid;

      if (!isTeacher && (!memberDoc.exists || memberDoc.data()?.status !== 'active')) {
        return res.status(403).json({
          error: 'Akses ditolak: Anda bukan anggota aktif kelas ini.',
        });
      }

      // Verifikasi status penugasan dan batas pengumpulan terlambat
      const assignDoc = await db.collection('classes').doc(cleanClassId).collection('assignments').doc(cleanAssignmentId).get();
      if (!assignDoc.exists) {
        return res.status(404).json({ error: 'Tugas tidak ditemukan.' });
      }

      if (!isTeacher) {
        const assignData = assignDoc.data() || {};
        const deadlineDate = assignData.deadline?.toDate ? assignData.deadline.toDate() : new Date(assignData.deadline);
        const now = new Date();
        if (now > deadlineDate && assignData.allow_late_submission === false) {
          return res.status(403).json({
            error: 'Batas waktu pengumpulan tugas telah berakhir dan pengumpulan terlambat tidak diizinkan.',
          });
        }
      }
    }
  } else {
    // folderType manual_books atau images: HANYA GURU atau ADMIN
    if (role !== 'GURU' && role !== 'ADMIN') {
      return res.status(403).json({
        error: 'Akses ditolak: Hanya Pengajar (Guru) atau Admin yang berhak mengunggah berkas modul.',
      });
    }

    // 2b. Validasi wewenang & kepemilikan kelas:
    // - Jika classId === 'SYSTEM', HANYA role ADMIN yang diizinkan (Manual Book / Aset Sistem Global)
    // - Jika kelas reguler, Guru wajib pemilik kelas (Admin bebas)
    if (cleanClassId === 'SYSTEM') {
      if (role !== 'ADMIN') {
        return res.status(403).json({
          error: 'Akses ditolak: Hanya Admin yang berhak mengunggah berkas sistem global.',
        });
      }
    } else if (role !== 'ADMIN') {
      const classDoc = await db.collection('classes').doc(cleanClassId).get();
      if (!classDoc.exists) {
        return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
      }
      const classData = classDoc.data() || {};
      if (classData.teacher_id !== user.uid) {
        return res.status(403).json({
          error: 'Akses ditolak: Anda bukan pengajar/pemilik kelas ini.',
        });
      }
    }
  }

  let folder: string;
  if (folderType === 'assignments') {
    const cleanAssignmentId = (assignmentId as string).trim();
    folder = `farlean/classes/${cleanClassId}/assignments/${cleanAssignmentId}/${user.uid}`;
  } else if (cleanClassId === 'SYSTEM') {
    folder = `farlean/system/${folderType === 'images' ? 'images' : 'manual_books'}`;
  } else if (folderType === 'assignment_instructions') {
    folder = `farlean/classes/${cleanClassId}/assignment_instructions`;
  } else {
    folder = `farlean/classes/${cleanClassId}/${folderType === 'images' ? 'images' : 'manual_books'}`;
  }

  // 3. Rate Limiting Request Signature (Mencegah flooding upload)
  const rateLimitRef = db.collection('rate_limits').doc(user.uid);

  try {
    await db.runTransaction(async (transaction) => {
      const now = Date.now();
      const rateDoc = await transaction.get(rateLimitRef);
      let attempts = 0;
      let windowStart = now;

      if (rateDoc.exists) {
        const rateData = rateDoc.data() || {};
        const lastStart = rateData.sign_window_start?.toMillis
            ? rateData.sign_window_start.toMillis()
            : (rateData.sign_window_start || 0);

        if (now - lastStart < RATE_LIMIT_WINDOW_MS) {
          attempts = rateData.sign_attempts || 0;
          windowStart = lastStart;

          if (attempts >= MAX_SIGN_ATTEMPTS) {
            throw {
              status: 429,
              message: 'Terlalu banyak permintaan tanda tangan unggahan. Harap tunggu 15 menit.',
            };
          }
        } else {
          attempts = 0;
          windowStart = now;
        }
      }

      transaction.set(
        rateLimitRef,
        {
          sign_attempts: attempts + 1,
          sign_window_start: typeof windowStart === 'number' ? new Date(windowStart) : windowStart,
          last_sign_attempt: FieldValue.serverTimestamp(),
        },
        { merge: true }
      );
    });

    // 4. Generate Cloudinary Signature di Server
    const timestamp = Math.round(Date.now() / 1000);
    const paramsToSign = {
      folder,
      timestamp,
    };

    const apiSecret = process.env.CLOUDINARY_API_SECRET || 'dev_secret_placeholder';
    const apiKey = process.env.CLOUDINARY_API_KEY || 'dev_key_placeholder';
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME || 'farlean';

    const signature = cloudinary.utils.api_sign_request(paramsToSign, apiSecret);

    return res.status(200).json({
      success: true,
      signature,
      timestamp,
      apiKey,
      cloudName,
      folder,
      uploadUrl: `https://api.cloudinary.com/v1_1/${cloudName}/auto/upload`,
    });
  } catch (error: any) {
    if (error && error.status && error.message) {
      return res.status(error.status).json({ error: error.message });
    }
    console.error('Error upload-sign:', error);
    return res.status(500).json({ error: 'Gagal menghasilkan tanda tangan unggahan.' });
  }
}
