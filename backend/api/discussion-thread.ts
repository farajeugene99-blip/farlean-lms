import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const ALLOWED_BODY_FIELDS = new Set(['classId', 'title', 'body', 'client_request_id']);
const RATE_LIMIT_WINDOW_MS = 15 * 60 * 1000; // 15 menit
const MAX_THREAD_PER_WINDOW = 10;
const THREAD_MIN_INTERVAL_MS = 10 * 1000; // 10 detik per class

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

  const { classId, title, body: contentBody, client_request_id } = body;

  if (!classId || typeof classId !== 'string' || classId.trim().length === 0) {
    return res.status(400).json({ error: 'classId wajib diisi.' });
  }

  if (!title || typeof title !== 'string' || title.trim().length < 3 || title.trim().length > 200) {
    return res.status(400).json({ error: 'Judul diskusi harus antara 3 hingga 200 karakter.' });
  }

  if (!contentBody || typeof contentBody !== 'string' || contentBody.trim().length < 3 || contentBody.trim().length > 5000) {
    return res.status(400).json({ error: 'Isi diskusi harus antara 3 hingga 5000 karakter.' });
  }

  let cleanClientRequestId: string | null = null;
  if (client_request_id !== undefined && client_request_id !== null) {
    if (typeof client_request_id !== 'string' || !/^[A-Za-z0-9_-]{8,64}$/.test(client_request_id.trim())) {
      return res.status(400).json({
        error: 'Format client_request_id tidak valid (harus 8-64 karakter alfanumerik, dash, atau underscore).',
      });
    }
    cleanClientRequestId = client_request_id.trim();
  }

  const cleanClassId = classId.trim();

  try {
    // 3. Cek Idempotensi Terlebih Dahulu (Sebelum Rate Limit)
    // Menggunakan ID ber-namespace: {uid}_{client_request_id}
    const discussionRef = cleanClientRequestId
      ? db.collection('discussions').doc(`${user.uid}_${cleanClientRequestId}`)
      : db.collection('discussions').doc();

    if (cleanClientRequestId) {
      const existingDoc = await discussionRef.get();
      if (existingDoc.exists) {
        const existingData = existingDoc.data() || {};
        if (existingData.author_id === user.uid) {
          // Bandingkan payload
          if (
            existingData.class_id === cleanClassId &&
            existingData.title === title.trim() &&
            existingData.body === contentBody.trim()
          ) {
            // Retry yang sah: kembalikan dokumen yang sama tanpa kena penalti rate limit
            return res.status(200).json({
              success: true,
              discussionId: existingDoc.id,
              idempotent: true,
              message: 'Diskusi berhasil dimuat kembali (idempotent).',
            });
          } else {
            // ID sama tetapi payload berbeda
            return res.status(409).json({
              error: 'client_request_id sudah pernah digunakan dengan data diskusi yang berbeda.',
            });
          }
        } else {
          return res.status(409).json({
            error: 'client_request_id mengalami konflik kepemilikan dokumen.',
          });
        }
      }
    }

    // 4. Rate Limiting Per-User (Hanya untuk dokumen baru)
    const rateLimitRef = db.collection('rate_limits').doc(user.uid);
    const rateLimitDoc = await rateLimitRef.get();
    const now = Date.now();
    const rateData = rateLimitDoc.data() || {};

    const lastThreadAtKey = `thread_last_at_${cleanClassId}`;
    const lastThreadAt = rateData[lastThreadAtKey] || 0;
    if (now - lastThreadAt < THREAD_MIN_INTERVAL_MS) {
      return res.status(429).json({
        error: 'Mohon tunggu 10 detik sebelum membuat diskusi baru di kelas ini.',
      });
    }

    const windowStart = rateData.thread_window_start || 0;
    const threadCount = rateData.thread_count || 0;

    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      if (threadCount >= MAX_THREAD_PER_WINDOW) {
        return res.status(429).json({
          error: 'Batas pembuatan diskusi terlampaui. Silakan tunggu beberapa saat sebelum membuat diskusi baru.',
        });
      }
    }

    // 5. Periksa Kelas
    const classDoc = await db.collection('classes').doc(cleanClassId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};
    if (classData.status === 'Archived') {
      return res.status(400).json({ error: 'Kelas berstatus Archived. Pembuatan diskusi baru ditolak.' });
    }

    // 6. Verifikasi Keanggotaan & Dapatkan Nama Terpercaya (Anti-Impersonasi)
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

    // 7. Simpan Dokumen Diskusi Secara Atomik bersama Rate Limit
    const newDiscussionData = {
      class_id: cleanClassId,
      title: title.trim(),
      body: contentBody.trim(),
      author_id: user.uid,
      author_display_name: authorDisplayName,
      status: 'ACTIVE',
      reply_count: 0,
      client_request_id: cleanClientRequestId,
      last_activity_at: FieldValue.serverTimestamp(),
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    };

    const batch = db.batch();
    batch.set(discussionRef, newDiscussionData);

    // Auto-read untuk pembuat thread di transaksi/batch yang sama
    const authorReadRef = db.collection('discussion_reads').doc(`${user.uid}_${discussionRef.id}`);
    batch.set(authorReadRef, {
      user_id: user.uid,
      discussion_id: discussionRef.id,
      class_id: cleanClassId,
      last_read_at: FieldValue.serverTimestamp(),
    });

    const rateUpdates: Record<string, any> = {
      [lastThreadAtKey]: now,
    };
    if (now - windowStart < RATE_LIMIT_WINDOW_MS) {
      rateUpdates.thread_count = threadCount + 1;
    } else {
      rateUpdates.thread_window_start = now;
      rateUpdates.thread_count = 1;
    }
    batch.set(rateLimitRef, rateUpdates, { merge: true });

    await batch.commit();

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
