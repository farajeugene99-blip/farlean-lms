import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set([
  'testId',
  'qid',
  'text',
  'options',
  'correct_option',
  'points',
  'explanation',
]);

export default async function handler(req: VercelRequest, res: VercelResponse) {
  // 1. CORS Preflight
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 2. Verifikasi Autentikasi (wajib email terverifikasi)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 3. Verifikasi Role (Hanya GURU dan ADMIN)
  const role = (user as any).role || 'USER';
  if (role !== 'GURU' && role !== 'ADMIN') {
    return res.status(403).json({
      error: 'Akses ditolak: Hanya Guru atau Admin yang berhak mengelola soal.',
    });
  }

  const body = req.body || {};

  // 4. Tolak field tidak sah (Strict Payload Validation)
  for (const key of Object.keys(body)) {
    if (!ALLOWED_BODY_FIELDS.has(key)) {
      return res.status(400).json({
        error: `Field tidak sah ditemukan dalam payload: ${key}`,
      });
    }
  }

  const { testId, qid, text, options, correct_option, points = 10, explanation = '' } = body;

  // 5. Validasi Field
  if (!testId || typeof testId !== 'string' || testId.trim().length === 0) {
    return res.status(400).json({ error: 'testId wajib diisi.' });
  }

  if (!text || typeof text !== 'string' || text.trim().length === 0 || text.trim().length > 2000) {
    return res.status(400).json({ error: 'Teks soal wajib diisi dan maksimal 2000 karakter.' });
  }

  if (!Array.isArray(options) || options.length < 2) {
    return res.status(400).json({ error: 'Pilihan jawaban wajib berupa array dengan minimal 2 opsi.' });
  }

  if (options.length > 10) {
    return res.status(400).json({ error: 'Pilihan jawaban maksimal 10 opsi.' });
  }

  const cleanedOptions: string[] = [];
  for (let i = 0; i < options.length; i++) {
    const opt = options[i];
    if (typeof opt !== 'string' || opt.trim().length === 0 || opt.trim().length > 500) {
      return res.status(400).json({
        error: `Opsi ke-${i + 1} tidak valid (harus string tidak kosong dan maksimal 500 karakter).`,
      });
    }
    cleanedOptions.push(opt.trim());
  }

  if (
    typeof correct_option !== 'number' ||
    !Number.isInteger(correct_option) ||
    correct_option < 0 ||
    correct_option >= cleanedOptions.length
  ) {
    return res.status(400).json({
      error: `Indeks kunci jawaban (correct_option) harus bilangan bulat antara 0 dan ${cleanedOptions.length - 1}.`,
    });
  }

  const parsedPoints = typeof points === 'number' && Number.isInteger(points) ? points : 10;
  if (parsedPoints < 1 || parsedPoints > 100) {
    return res.status(400).json({ error: 'Poin soal harus berupa bilangan bulat antara 1 dan 100.' });
  }

  if (explanation && (typeof explanation !== 'string' || explanation.length > 1000)) {
    return res.status(400).json({ error: 'Penjelasan maksimal 1000 karakter.' });
  }

  const cleanTestId = testId.trim();

  try {
    // 6. Temukan Dokumen Induk (Periksa pretests dan posttests dari Firestore langsung)
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

    // 7. Verifikasi Hak Akses Kelas & Status Kelas
    const classDoc = await db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas induk tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};

    // Cek kelas Archived (Admin SDK melewati Firestore Rules, wajib ditegakkan di backend)
    if (classData.status === 'Archived') {
      return res.status(400).json({
        error: 'Kelas berstatus Archived. Perubahan pada kuis atau soal ditolak.',
      });
    }

    // Cek Ownership: Guru hanya boleh mengelola kelas miliknya
    if (role !== 'ADMIN' && classData.teacher_id !== user.uid) {
      return res.status(403).json({
        error: 'Akses ditolak: Anda bukan pemilik kelas ini.',
      });
    }

    // 8. Tentukan ID Soal & Versioning
    const questionsSubcol = db.collection(parentCollection).doc(cleanTestId).collection('questions');
    const answerKeyItemsSubcol = db.collection('answer_keys').doc(cleanTestId).collection('items');

    const targetQid = (qid && typeof qid === 'string' && qid.trim().length > 0)
      ? qid.trim()
      : questionsSubcol.doc().id;

    const existingQDoc = await questionsSubcol.doc(targetQid).get();
    const currentVersion = existingQDoc.exists ? (existingQDoc.data()?.version || 1) : 0;
    const newVersion = currentVersion + 1;

    // 9. Simpan Secara Atomik menggunakan Batch (Questions + Answer Key)
    const batch = db.batch();

    // Dokumen Soal (TIDAK MEMUAT correct_option atau explanation rahasia)
    batch.set(
      questionsSubcol.doc(targetQid),
      {
        text: text.trim(),
        type: 'multiple_choice',
        options: cleanedOptions,
        points: parsedPoints,
        tag: 'general',
        version: newVersion,
        deleted: false,
        updated_by: user.uid,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    // Dokumen Kunci Jawaban (Server-Only, isolasi rahasia)
    batch.set(
      answerKeyItemsSubcol.doc(targetQid),
      {
        qid: targetQid,
        correct_option,
        explanation: explanation ? explanation.trim() : '',
        points: parsedPoints,
        version: newVersion,
        deleted: false,
        updated_by: user.uid,
        updated_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    await batch.commit();

    return res.status(200).json({
      success: true,
      qid: targetQid,
      version: newVersion,
      message: 'Soal dan kunci jawaban berhasil disimpan secara atomik.',
    });
  } catch (err: any) {
    console.error('Error in save-question:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat menyimpan soal.' });
  }
}
