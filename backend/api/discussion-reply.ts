import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set(['discussionId', 'body', 'client_reply_id', 'parent_id']);
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_REPLY_PER_WINDOW = 30;
const REPLY_MIN_INTERVAL_MS = 3 * 1000; // 3 detik per user

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

  const { discussionId, body: contentBody, client_reply_id, parent_id } = body;

  if (!discussionId || typeof discussionId !== 'string' || discussionId.trim().length === 0) {
    return res.status(400).json({ error: 'discussionId wajib diisi.' });
  }

  if (!contentBody || typeof contentBody !== 'string' || contentBody.trim().length === 0 || contentBody.trim().length > 2000) {
    return res.status(400).json({ error: 'Isi balasan harus antara 1 hingga 2000 karakter.' });
  }

  let cleanClientReplyId: string | null = null;
  if (client_reply_id !== undefined && client_reply_id !== null) {
    if (typeof client_reply_id !== 'string' || !/^[A-Za-z0-9_-]{8,64}$/.test(client_reply_id.trim())) {
      return res.status(400).json({
        error: 'Format client_reply_id tidak valid (harus 8-64 karakter alfanumerik, dash, atau underscore).',
      });
    }
    cleanClientReplyId = client_reply_id.trim();
  }

  let cleanParentId: string | null = null;
  if (parent_id !== undefined && parent_id !== null) {
    if (typeof parent_id !== 'string' || parent_id.trim().length === 0) {
      return res.status(400).json({ error: 'Format parent_id tidak valid.' });
    }
    cleanParentId = parent_id.trim();
  }

  const cleanDiscussionId = discussionId.trim();

  try {
    const discussionRef = db.collection('discussions').doc(cleanDiscussionId);
    const replyRef = cleanClientReplyId
      ? discussionRef.collection('replies').doc(`${user.uid}_${cleanClientReplyId}`)
      : discussionRef.collection('replies').doc();

    // 3. Cek Idempotensi Terlebih Dahulu (Sebelum Rate Limit)
    if (cleanClientReplyId) {
      const existingReply = await replyRef.get();
      if (existingReply.exists) {
        const repData = existingReply.data() || {};
        if (repData.author_id === user.uid) {
          if (repData.body === contentBody.trim()) {
            return res.status(200).json({
              success: true,
              replyId: existingReply.id,
              idempotent: true,
              message: 'Balasan berhasil dimuat kembali (idempotent).',
            });
          } else {
            return res.status(409).json({
              error: 'client_reply_id sudah pernah digunakan dengan isi balasan yang berbeda.',
            });
          }
        } else {
          return res.status(409).json({
            error: 'client_reply_id mengalami konflik kepemilikan dokumen.',
          });
        }
      }
    }

    // 4. Rate Limiting Per-User (Hanya untuk balasan baru)
    const rateLimitRef = db.collection('rate_limits').doc(user.uid);
    const rateLimitDoc = await rateLimitRef.get();
    const now = Date.now();
    const rateData = rateLimitDoc.data() || {};

    const lastReplyAt = rateData.last_reply_at_timestamp || 0;
    if (now - lastReplyAt < REPLY_MIN_INTERVAL_MS) {
      return res.status(429).json({
        error: 'Mohon tunggu 3 detik sebelum mengirim balasan berikutnya.',
      });
    }

    const windowStart = rateData.reply_window_start || 0;
    const replyCount = rateData.reply_count || 0;

    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      if (replyCount >= MAX_REPLY_PER_WINDOW) {
        return res.status(429).json({
          error: 'Batas pengiriman balasan terlampaui. Silakan tunggu beberapa saat.',
        });
      }
    }

    // 5. Periksa Dokumen Induk Diskusi
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

    // 6. Periksa Kelas & Hak Keanggotaan
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

    let resolvedParentId: string | null = null;
    let parentAuthorName: string | null = null;

    if (cleanParentId) {
      const parentReplyDoc = await discussionRef.collection('replies').doc(cleanParentId).get();
      if (!parentReplyDoc.exists) {
        return res.status(404).json({ error: 'Balasan induk yang dituju tidak ditemukan.' });
      }
      const parentData = parentReplyDoc.data() || {};
      if (parentData.status === 'ARCHIVED') {
        return res.status(400).json({ error: 'Balasan induk telah diarsipkan. Pengiriman balasan ditolak.' });
      }

      // Twitter/X Flattening: Jika induk sudah memiliki parent_id, ratakan ke root parent
      if (parentData.parent_id) {
        resolvedParentId = parentData.parent_id;
      } else {
        resolvedParentId = cleanParentId;
      }
      parentAuthorName = parentData.author_display_name || 'Pengguna';
    }

    // 7. Transaksi Atomik: Buat Balasan + Increment reply_count & update last_activity_at di Induk + update Rate Limit
    await db.runTransaction(async (transaction) => {
      const freshDiscussionDoc = await transaction.get(discussionRef);
      if (!freshDiscussionDoc.exists) {
        throw { status: 404, message: 'Diskusi tidak ditemukan saat transaksi.' };
      }
      if (freshDiscussionDoc.data()?.status === 'ARCHIVED') {
        throw { status: 400, message: 'Diskusi telah diarsipkan saat transaksi.' };
      }

      // Tulis subkoleksi balasan
      const replyData: Record<string, any> = {
        discussion_id: cleanDiscussionId,
        author_id: user.uid,
        author_display_name: authorDisplayName,
        body: contentBody.trim(),
        client_reply_id: cleanClientReplyId,
        status: 'ACTIVE',
        created_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      };

      if (resolvedParentId) {
        replyData.parent_id = resolvedParentId;
        replyData.parent_author_name = parentAuthorName;
      }

      transaction.set(replyRef, replyData);

      // Update metadata induk diskusi (menaikkan last_activity_at)
      transaction.update(discussionRef, {
        reply_count: FieldValue.increment(1),
        last_activity_at: FieldValue.serverTimestamp(),
        updated_at: FieldValue.serverTimestamp(),
      });

      // Auto-read untuk pembuat balasan di transaksi yang sama (tidak unread bagi diri sendiri)
      const authorReadRef = db.collection('discussion_reads').doc(`${user.uid}_${cleanDiscussionId}`);
      transaction.set(authorReadRef, {
        user_id: user.uid,
        discussion_id: cleanDiscussionId,
        class_id: classId,
        last_read_at: FieldValue.serverTimestamp(),
      }, { merge: true });

      // Update Rate Limit di transaksi yang sama
      const rateUpdates: Record<string, any> = {
        last_reply_at_timestamp: now,
      };
      if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
        rateUpdates.reply_count = replyCount + 1;
      } else {
        rateUpdates.reply_window_start = now;
        rateUpdates.reply_count = 1;
      }
      transaction.set(rateLimitRef, rateUpdates, { merge: true });
    });

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
