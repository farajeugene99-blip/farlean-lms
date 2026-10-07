import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_STATUSES = new Set(['Draft', 'Published', 'Archived']);

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Autentikasi (wajib email terverifikasi)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 2. Verifikasi Role (Hanya GURU dan ADMIN)
  const role = (user as any).role || 'USER';
  if (role !== 'GURU' && role !== 'ADMIN') {
    return res.status(403).json({
      error: 'Akses ditolak: Hanya Guru atau Admin yang berhak mengubah status publikasi kuis.',
    });
  }

  const { testId, status } = req.body || {};

  if (!testId || typeof testId !== 'string' || testId.trim().isEmpty) {
    return res.status(400).json({ error: 'testId wajib diisi.' });
  }

  if (!status || typeof status !== 'string' || !ALLOWED_STATUSES.has(status)) {
    return res.status(400).json({
      error: 'status harus salah satu dari: Draft, Published, Archived.',
    });
  }

  const cleanTestId = testId.trim();

  try {
    // 3. Temukan Dokumen Induk (pretests atau posttests)
    let parentDoc = await db.collection('pretests').doc(cleanTestId).get();
    let parentCollection = 'pretests';

    if (!parentDoc.exists) {
      parentDoc = await db.collection('posttests').doc(cleanTestId).get();
      parentCollection = 'posttests';
    }

    if (!parentDoc.exists) {
      return res.status(404).json({ error: 'Kuis tidak ditemukan.' });
    }

    const testData = parentDoc.data() || {};
    const classId = testData.class_id;

    if (!classId) {
      return res.status(400).json({ error: 'Kuis tidak memiliki class_id yang valid.' });
    }

    // 4. Verifikasi Kelas & Hak Akses
    const classDoc = await db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas induk tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};

    if (classData.status === 'Archived') {
      return res.status(400).json({
        error: 'Kelas berstatus Archived. Perubahan status publikasi kuis ditolak.',
      });
    }

    if (role !== 'ADMIN' && classData.teacher_id !== user.uid) {
      return res.status(403).json({
        error: 'Akses ditolak: Anda bukan pemilik kelas ini.',
      });
    }

    // 5. Validasi Aturan Transisi Status
    if (status === 'Published') {
      // Wajib minimal ada 1 soal aktif non-deleted
      const questionsSnap = await db
        .collection(parentCollection)
        .doc(cleanTestId)
        .collection('questions')
        .get();

      const activeQuestions = questionsSnap.docs.filter((d) => d.data().deleted !== true);

      if (activeQuestions.length === 0) {
        return res.status(400).json({
          error: 'Kuis tidak dapat dipublikasikan karena belum memiliki soal aktif. Silakan tambahkan minimal 1 soal.',
        });
      }

      // Pastikan ada kunci jawaban yang valid
      const keysSnap = await db
        .collection('answer_keys')
        .doc(cleanTestId)
        .collection('items')
        .get();

      const activeKeys = keysSnap.docs.filter((d) => d.data().deleted !== true);
      if (activeKeys.length === 0) {
        return res.status(400).json({
          error: 'Kuis belum memiliki kunci jawaban yang valid di server.',
        });
      }
    } else if (status === 'Draft') {
      // Jika kuis sudah pernah dikerjakan oleh siswa, DILARANG kembali ke status Draft
      const attemptsSnap = await db
        .collection('attempts')
        .where('test_id', '==', cleanTestId)
        .limit(1)
        .get();

      if (!attemptsSnap.empty) {
        return res.status(400).json({
          error: 'Kuis yang sudah dikerjakan siswa tidak dapat dikembalikan ke status Draft. Silakan ubah ke status Archived jika ingin menonaktifkan kuis ini.',
        });
      }
    }

    // 6. Update status dokumen kuis
    await db.collection(parentCollection).doc(cleanTestId).update({
      status,
      updated_at: FieldValue.serverTimestamp(),
      updated_by: user.uid,
    });

    return res.status(200).json({
      success: true,
      testId: cleanTestId,
      status,
      message: `Status kuis berhasil diubah menjadi ${status}.`,
    });
  } catch (err: any) {
    console.error('Error publish-test:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat memperbarui status kuis.' });
  }
}
