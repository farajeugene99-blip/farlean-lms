import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set(['classId', 'title', 'body']);
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_THREAD_PER_WINDOW = 10;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Autentikasi (wajib email terverifikasi)
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const body = req.body || {};

  // 2. Strict Payload Validation
  for (const key of Object.keys(body)) {
    if (!ALLOWED_BODY_FIELDS.has(key)) {
      return res.status(400).json({ error: `Field tidak sah ditemukan dalam payload: ${key}` });
    }
  }

  const { classId, title, body: contentBody } = body;

  if (!classId || typeof classId !== 'string' || classId.trim().length === 0) {
    return res.status(400).json({ error: 'classId wajib diisi.' });
  }

  if (!title || typeof title !== 'string' || title.trim().length < 3 || title.trim().length > 200) {
    return res.status(400).json({ error: 'Judul diskusi harus antara 3 hingga 200 karakter.' });
  }

  if (!contentBody || typeof contentBody !== 'string' || contentBody.trim().length < 3 || contentBody.trim().length > 5000) {
    return res.status(400).json({ error: 'Isi diskusi harus antara 3 hingga 5000 karakter.' });
  }

  const cleanClassId = classId.trim();

  try {
    // 3. Rate Limiting Per-User
    const rateLimitRef = db.collection('rate_limits').doc(user.uid);
    const rateLimitDoc = await rateLimitRef.get();
    const now = Date.now();
    const rateData = rateLimitDoc.data() || {};

    const windowStart = rateData.thread_window_start || 0;
    const threadCount = rateData.thread_count || 0;

    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      if (threadCount >= MAX_THREAD_PER_WINDOW) {
        return res.status(429).json({
          error: 'Batas pembuatan diskusi terlampaui. Silakan tunggu beberapa saat sebelum membuat diskusi baru.',
        });
      }
    }

    // 4. Periksa Kelas
    const classDoc = await db.collection('classes').doc(cleanClassId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};
    if (classData.status === 'Archived') {
      return res.status(400).json({ error: 'Kelas berstatus Archived. Pembuatan diskusi baru ditolak.' });
    }

    // 5. Verifikasi Keanggotaan & Dapatkan Nama Terpercaya (Anti-Impersonasi)
    const role = (user as any).role || 'USER';
    const isOwner = classData.teacher_id === user.uid || role === 'ADMIN';

    let authorDisplayName = '';
    const memberDoc = await db.collection('classes').doc(cleanClassId).collection('members').doc(user.uid).get();

    if (memberDoc.exists && memberDoc.data()?.status === 'active') {
      authorDisplayName = memberDoc.data()?.display_name || user.email?.split('@')[0] || 'Anggota Kelas';
    } else if (isOwner) {
      const teacherUserDoc = await db.collection('users').doc(user.uid).get();
      authorDisplayName = teacherUserDoc.data()?.name || user.email?.split('@')[0] || 'Pengajar';
    } else {
      return res.status(403).json({
        error: 'Akses ditolak: Anda bukan anggota aktif di kelas ini.',
      });
    }

    // 6. Simpan Dokumen Diskusi
    const discussionRef = db.collection('discussions').doc();
    const newDiscussionData = {
      class_id: cleanClassId,
      title: title.trim(),
      body: contentBody.trim(),
      author_id: user.uid,
      author_display_name: authorDisplayName,
      status: 'ACTIVE',
      reply_count: 0,
      last_activity_at: FieldValue.serverTimestamp(),
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    };

    await discussionRef.set(newDiscussionData);

    // 7. Update Counter Rate Limit
    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      await rateLimitRef.set(
        { thread_count: threadCount + 1, last_thread_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
    } else {
      await rateLimitRef.set(
        { thread_window_start: now, thread_count: 1, last_thread_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    return res.status(201).json({
      success: true,
      discussionId: discussionRef.id,
      message: 'Diskusi berhasil dibuat.',
    });
  } catch (err: any) {
    console.error('Error discussion-thread:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat membuat diskusi.' });
  }
}
