import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set(['testId', 'qid']);

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 1. CORS Preflight
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 2. Verifikasi Autentikasi
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 3. Verifikasi Role (Hanya GURU dan ADMIN)
  const role = (user as any).role || 'USER';
  if (role !== 'GURU' && role !== 'ADMIN') {
    return res.status(403).json({
      error: 'Akses ditolak: Hanya Guru atau Admin yang berhak menghapus soal.',
    });
  }

  const body = req.body || {};

  // 4. Tolak field tidak sah
  for (const key of Object.keys(body)) {
    if (!ALLOWED_BODY_FIELDS.has(key)) {
      return res.status(400).json({
        error: `Field tidak sah ditemukan dalam payload: ${key}`,
      });
    }
  }

  const { testId, qid } = body;

  if (!testId || typeof testId !== 'string' || testId.trim().length === 0) {
    return res.status(400).json({ error: 'testId wajib diisi.' });
  }

  if (!qid || typeof qid !== 'string' || qid.trim().length === 0) {
    return res.status(400).json({ error: 'qid wajib diisi.' });
  }

  const cleanTestId = testId.trim();
  const cleanQid = qid.trim();

  try {
    // 5. Temukan Dokumen Induk (pretests atau posttests)
    let parentDoc = await db.collection('pretests').doc(cleanTestId).get();
    let parentCollection = 'pretests';

    if (!parentDoc.exists) {
      parentDoc = await db.collection('posttests').doc(cleanTestId).get();
      parentCollection = 'posttests';
    }

    if (!parentDoc.exists) {
      return res.status(404).json({ error: 'Kuis (pretest/posttest) tidak ditemukan.' });
    }

    const parentData = parentDoc.data() || {};
    const classId = parentData.class_id;
    if (!classId) {
      return res.status(400).json({ error: 'Kuis tidak memiliki asosiasi class_id yang valid.' });
    }

    // 6. Verifikasi Kepemilikan & Status Kelas
    const classDoc = await db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas induk tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};

    if (classData.status === 'Archived') {
      return res.status(400).json({
        error: 'Kelas berstatus Archived. Penghapusan soal ditolak.',
      });
    }

    if (role !== 'ADMIN' && classData.teacher_id !== user.uid) {
      return res.status(403).json({
        error: 'Akses ditolak: Anda bukan pemilik kelas ini.',
      });
    }

    const questionsSubcol = db.collection(parentCollection).doc(cleanTestId).collection('questions');
    const answerKeyItemsSubcol = db.collection('answer_keys').doc(cleanTestId).collection('items');

    // 7. Proteksi Kuis Published: Dilarang menghapus soal aktif terakhir pada kuis Published
    if (parentData.status === 'Published') {
      const activeQuestionsSnap = await questionsSubcol.get();
      const activeCount = activeQuestionsSnap.docs.filter((d) => d.data().deleted !== true).length;
      if (activeCount <= 1) {
        return res.status(400).json({
          error: 'Tidak dapat menghapus soal aktif terakhir pada kuis yang berstatus Published. Silakan arsipkan kuis terlebih dahulu jika ingin menonaktifkannya.',
        });
      }
    }

    // 8. Cek apakah ada attempt pengerjaan untuk testId ini
    const attemptsSnap = await db
      .collection('attempts')
      .where('test_id', '==', cleanTestId)
      .limit(1)
      .get();

    const hasAttempts = !attemptsSnap.empty;

    const batch = db.batch();

    if (hasAttempts) {
      // Soft-delete agar riwayat jawaban mahasiswa di masa lalu tidak orphan
      batch.update(questionsSubcol.doc(cleanQid), {
        deleted: true,
        status: 'Archived',
        updated_by: user.uid,
        updated_at: FieldValue.serverTimestamp(),
      });

      batch.update(answerKeyItemsSubcol.doc(cleanQid), {
        deleted: true,
        updated_by: user.uid,
        updated_at: FieldValue.serverTimestamp(),
      });
    } else {
      // Hard-delete aman karena belum pernah ada attempt yang merujuk soal ini
      batch.delete(questionsSubcol.doc(cleanQid));
      batch.delete(answerKeyItemsSubcol.doc(cleanQid));
    }

    await batch.commit();

    return res.status(200).json({
      success: true,
      qid: cleanQid,
      softDeleted: hasAttempts,
      message: hasAttempts
        ? 'Soal berhasil diarsipkan (soft-delete) untuk melindungi riwayat pengerjaan siswa.'
        : 'Soal dan kunci jawaban berhasil dihapus permanen.',
    });
  } catch (err: any) {
    console.error('Error in delete-question:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat menghapus soal.' });
  }
}
