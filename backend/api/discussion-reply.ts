import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set(['discussionId', 'body']);
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_REPLY_PER_WINDOW = 30;

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Autentikasi
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const body = req.body || {};

  // 2. Strict Payload Validation
  for (const key of Object.keys(body)) {
    if (!ALLOWED_BODY_FIELDS.has(key)) {
      return res.status(400).json({ error: `Field tidak sah ditemukan dalam payload: ${key}` });
    }
  }

  const { discussionId, body: contentBody } = body;

  if (!discussionId || typeof discussionId !== 'string' || discussionId.trim().length === 0) {
    return res.status(400).json({ error: 'discussionId wajib diisi.' });
  }

  if (!contentBody || typeof contentBody !== 'string' || contentBody.trim().length === 0 || contentBody.trim().length > 2000) {
    return res.status(400).json({ error: 'Isi balasan harus antara 1 hingga 2000 karakter.' });
  }

  const cleanDiscussionId = discussionId.trim();

  try {
    // 3. Rate Limiting Per-User
    const rateLimitRef = db.collection('rate_limits').doc(user.uid);
    const rateLimitDoc = await rateLimitRef.get();
    const now = Date.now();
    const rateData = rateLimitDoc.data() || {};

    const windowStart = rateData.reply_window_start || 0;
    const replyCount = rateData.reply_count || 0;

    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      if (replyCount >= MAX_REPLY_PER_WINDOW) {
        return res.status(429).json({
          error: 'Batas pengiriman balasan terlampaui. Silakan tunggu beberapa saat.',
        });
      }
    }

    // 4. Periksa Dokumen Induk Diskusi
    const discussionRef = db.collection('discussions').doc(cleanDiscussionId);
    const discussionDoc = await discussionRef.get();

    if (!discussionDoc.exists) {
      return res.status(404).json({ error: 'Diskusi tidak ditemukan.' });
    }

    const discussionData = discussionDoc.data() || {};
    if (discussionData.status === 'ARCHIVED') {
      return res.status(400).json({ error: 'Diskusi ini telah diarsipkan. Balasan baru ditolak.' });
    }

    const classId = discussionData.class_id;
    if (!classId) {
      return res.status(400).json({ error: 'Diskusi tidak memiliki class_id yang valid.' });
    }

    // 5. Periksa Kelas & Hak Keanggotaan
    const classDoc = await db.collection('classes').doc(classId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas induk diskusi tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};
    if (classData.status === 'Archived') {
      return res.status(400).json({ error: 'Kelas berstatus Archived. Pengiriman balasan baru ditolak.' });
    }

    const role = (user as any).role || 'USER';
    const isOwner = classData.teacher_id === user.uid || role === 'ADMIN';

    let authorDisplayName = '';
    const memberDoc = await db.collection('classes').doc(classId).collection('members').doc(user.uid).get();

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

    // 6. Transaksi Atomik: Buat Balasan + Increment reply_count & update last_activity_at di Induk
    const replyRef = discussionRef.collection('replies').doc();

    await db.runTransaction(async (transaction) => {
      const freshDiscussionDoc = await transaction.get(discussionRef);
      if (!freshDiscussionDoc.exists) {
        throw { status: 404, message: 'Diskusi tidak ditemukan saat transaksi.' };
      }
      if (freshDiscussionDoc.data()?.status === 'ARCHIVED') {
        throw { status: 400, message: 'Diskusi telah diarsipkan saat transaksi.' };
      }

      // Tulis subkoleksi balasan
      transaction.set(replyRef, {
        discussion_id: cleanDiscussionId,
        author_id: user.uid,
        author_display_name: authorDisplayName,
        body: contentBody.trim(),
        status: 'ACTIVE',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      // Update metadata induk diskusi (menaikkan last_activity_at)
      transaction.update(discussionRef, {
        reply_count: FieldValue.increment(1),
        last_activity_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });
    });

    // 7. Update Counter Rate Limit
    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      await rateLimitRef.set(
        { reply_count: replyCount + 1, last_reply_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
    } else {
      await rateLimitRef.set(
        { reply_window_start: now, reply_count: 1, last_reply_at: FieldValue.serverTimestamp() },
        { merge: true }
      );
    }

    return res.status(201).json({
      success: true,
      replyId: replyRef.id,
      message: 'Balasan berhasil dikirim.',
    });
  } catch (err: any) {
    if (err && err.status && err.message) {
      return res.status(err.status).json({ error: err.message });
    }
    console.error('Error discussion-reply:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat memproses balasan.' });
  }
}
