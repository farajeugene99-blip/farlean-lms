import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const GRACE_PERIOD_MS = 60 * 1000; // 60 detik toleransi jaringan (Blueprint Farlean LMS v1.4)

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi ID token (Wajib email terverifikasi)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const { attemptId } = req.body || {};
  if (!attemptId || typeof attemptId !== 'string') {
    return res.status(400).json({ error: 'attemptId wajib diisi.' });
  }

  try {
    const attemptRef = db.collection('attempts').doc(attemptId.trim());

    // 2. Eksekusi Transaksi Atomik: Idempotensi, Validasi Status, dan Grading
    const result = await db.runTransaction(async (transaction) => {
      const now = Date.now();

      // A. Baca dokumen attempt
      const attemptDoc = await transaction.get(attemptRef);
      if (!attemptDoc.exists) {
        throw { status: 404, message: 'Attempt tidak ditemukan.' };
      }

      const attemptData = attemptDoc.data() || {};

      // B. Validasi Kepemilikan Attempt
      if (attemptData.user_id !== user.uid) {
        throw { status: 403, message: 'Akses ditolak: Attempt ini bukan milik Anda.' };
      }

      // C. PENEGAKAN IDEMPOTENSI: Jika attempt sudah dinilai sebelumnya, kembalikan hasil yang ada
      if (attemptData.status === 'graded' || attemptData.status === 'submitted') {
        return {
          idempotent: true,
          attemptId: attemptDoc.id,
          score: attemptData.score ?? 0,
          pointsEarned: attemptData.points_earned ?? 0,
          totalPoints: attemptData.total_points ?? 0,
          status: attemptData.status,
          message: 'Hasil kuis telah dinilai sebelumnya.',
        };
      }

      if (attemptData.status !== 'in_progress') {
        throw { status: 400, message: `Status attempt tidak valid: ${attemptData.status}` };
      }

      const classId = attemptData.class_id;
      const testId = attemptData.test_id;

      // D. Validasi Keanggotaan Kelas (User wajib active member atau staff)
      if (classId) {
        const memberRef = db.collection('classes').doc(classId).collection('members').doc(user.uid);
        const memberDoc = await transaction.get(memberRef);

        const role = (user as any).role || 'USER';
        const isStaff = role === 'GURU' || role === 'ADMIN';

        if (!isStaff) {
          if (!memberDoc.exists || memberDoc.data()?.status !== 'active') {
            throw { status: 403, message: 'Akses ditolak: Anda bukan anggota aktif di kelas ini.' };
          }
        }
      }

      // E. Baca Dokumen Pretest atau Posttest & Validasi Status dan Deadline
      const isPosttest = attemptData.kind === 'posttest';
      let testDoc = await transaction.get(
        db.collection(isPosttest ? 'posttests' : 'pretests').doc(testId)
      );

      // Fallback: jika kind tidak diset, periksa apakah dokumen ada di posttests
      let resolvedScoreSubcol = isPosttest ? 'posttest_scores' : 'pretest_scores';
      if (!testDoc.exists && !isPosttest) {
        const altDoc = await transaction.get(db.collection('posttests').doc(testId));
        if (altDoc.exists) {
          testDoc = altDoc;
          resolvedScoreSubcol = 'posttest_scores';
        }
      }

      if (!testDoc.exists) {
        throw { status: 404, message: 'Kuis pembelajaran tidak ditemukan.' };
      }

      const testData = testDoc.data() || {};
      if (testData.status === 'Draft') {
        throw { status: 400, message: 'Kuis masih berstatus Draft dan belum dibuka.' };
      }
      if (testData.status === 'Archived') {
        throw { status: 400, message: 'Kuis telah diarsipkan.' };
      }

      // F. Validasi Deadline Waktu Server (+ 60 detik toleransi)
      if (testData.deadline) {
        const deadlineMs = testData.deadline.toMillis
            ? testData.deadline.toMillis()
            : new Date(testData.deadline).getTime();

        if (now > deadlineMs + GRACE_PERIOD_MS) {
          throw { status: 400, message: 'Batas waktu pengerjaan (deadline) kuis telah berakhir.' };
        }
      }

      // G. Baca Dokumen Best Score sebelumnya (Semua read harus sebelum write)
      let bestDoc: any = null;
      let bestScoreRef: any = null;
      if (classId) {
        bestScoreRef = db
            .collection('classes')
            .doc(classId)
            .collection(resolvedScoreSubcol)
            .doc(`${testId}_${user.uid}`);
        bestDoc = await transaction.get(bestScoreRef);
      }

      // H. Ambil Kunci Jawaban Rahasia Server-Side dari answer_keys/{testId}/items
      const keysSnapshot = await db
          .collection('answer_keys')
          .doc(testId)
          .collection('items')
          .get();

      if (keysSnapshot.empty) {
        throw { status: 500, message: 'Kunci jawaban belum dikonfigurasi di server.' };
      }

      let totalPoints = 0;
      let pointsEarned = 0;
      const userAnswers = attemptData.answers || {};

      for (const keyDoc of keysSnapshot.docs) {
        const keyData = keyDoc.data();
        const qid = keyDoc.id;
        const qPoints = keyData.points || 10;
        totalPoints += qPoints;

        const correctAnswer = keyData.correct_option;
        const studentAnswer = userAnswers[qid];

        if (studentAnswer !== undefined && studentAnswer === correctAnswer) {
          pointsEarned += qPoints;
        }
      }

      const finalScore = totalPoints > 0
          ? Math.round((pointsEarned / totalPoints) * 100 * 10) / 10
          : 0;

      // H. Kunci Attempt (Lock) dalam Transaksi: status menjadi 'graded'
      transaction.update(attemptRef, {
        status: 'graded',
        score: finalScore,
        points_earned: pointsEarned,
        total_points: totalPoints,
        submitted_at: FieldValue.serverTimestamp(),
      });

      // I. Simpan / Perbarui Best Score Pengguna
      if (classId && bestScoreRef) {
        const prevBest = bestDoc?.exists ? (bestDoc.data()?.best_score || 0) : -1;

        if (finalScore > prevBest) {
          transaction.set(
            bestScoreRef,
            {
              user_id: user.uid,
              test_id: testId,
              class_id: classId,
              best_score: finalScore,
              updated_at: FieldValue.serverTimestamp(),
            },
            { merge: true }
          );
        }
      }

      return {
        idempotent: false,
        attemptId: attemptDoc.id,
        score: finalScore,
        pointsEarned,
        totalPoints,
        status: 'graded',
        message: 'Kuis berhasil dinilai.',
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
    console.error('Error in /api/grade:', error);
    return res.status(500).json({ error: 'Terjadi kesalahan pada server saat menghitung nilai kuis.' });
  }
}
