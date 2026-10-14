import type { VercelRequest, VercelResponse } from '@vercel/node';
import { timingSafeEqual } from 'crypto';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const MAX_PROMOTIONS_PER_RUN = 200;

function safeCompare(a: string, b: string): boolean {
  if (!a || !b) return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

/**
 * GET / POST /api/publish-meetings
 *
 * Mekanisme promosi publikasi terjadwal Farlean LMS (C3):
 * - Mendukung GET (Vercel Cron bawaan) dan POST (panggilan manual staff).
 * - Memindai meetings berstatus `Scheduled` yang `publish_at`-nya telah lewat (<= now)
 *   lalu mempromosikannya menjadi `Published` secara idempoten.
 * - TIDAK memakai time-gate di Firestore Rules (rules tetap `status in [Published, Scheduled]`
 *   untuk baca mahasiswa; modul materi/pretest/posttest/video tetap mensyaratkan `Published`).
 *
 * Otorisasi dua mode:
 *  1. Cron terjadwal: (Vercel Cron) `Authorization: Bearer $CRON_SECRET` ATAU `x-cron-secret`
 *     -> sweep global tanpa cek kepemilikan kelas. Menggunakan timingSafeEqual.
 *  2. Staff manual: Bearer Firebase ID token, role GURU/ADMIN terverifikasi email.
 *     - ADMIN  -> boleh mempromosikan semua kelas.
 *     - GURU   -> hanya pertemuan pada kelas yang dimilikinya (classes/{id}.teacher_id == uid).
 *     - Opsional `classId` di query/body untuk membatasi sweep ke satu kelas.
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST' && req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  const body = req.body || {};
  const query = req.query || {};
  const rawClassId = body.classId || query.classId;
  const cleanClassId =
    typeof rawClassId === 'string' && rawClassId.trim().length > 0 ? rawClassId.trim() : null;

  const cronSecret = process.env.CRON_SECRET || process.env.MEETING_PUBLISH_CRON_SECRET || '';
  const providedHeaderSecret = (req.headers['x-cron-secret'] as string | undefined) || '';
  const authHeader = (req.headers.authorization as string | undefined) || '';
  const providedBearerSecret = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : '';

  const isVercelCronCall =
    cronSecret.length > 0 &&
    (safeCompare(providedBearerSecret, cronSecret) || safeCompare(providedHeaderSecret, cronSecret));
  const isCronCall = isVercelCronCall;

  let callerUid: string | null = null;
  let callerRole: string | null = null;
  let isAdminCaller = false;

  if (!isCronCall) {
    const user = await verifyAuth(req, res, { requireEmailVerified: true });
    if (!user) return;

    callerUid = user.uid as string;
    callerRole = ((user as any).role as string) || 'USER';
    if (callerRole !== 'GURU' && callerRole !== 'ADMIN') {
      return res.status(403).json({
        error: 'Akses ditolak: Hanya Guru, Admin, atau cron terjadwal yang boleh memicu publikasi.',
      });
    }
    isAdminCaller = callerRole === 'ADMIN';
  }

  try {
    // Jika classId diberikan, validasi kepemilikan kelas terlebih dahulu (mode staff).
    let scopedTeacherId: string | null = null;
    if (cleanClassId && !isCronCall && !isAdminCaller) {
      const classDoc = await db.collection('classes').doc(cleanClassId).get();
      if (!classDoc.exists) {
        return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
      }
      const classData = classDoc.data() || {};
      if (classData.teacher_id !== callerUid) {
        return res.status(403).json({ error: 'Akses ditolak: Anda bukan pemilik kelas ini.' });
      }
      scopedTeacherId = classData.teacher_id as string;
    }

    let query: FirebaseFirestore.Query = db
      .collection('meetings')
      .where('status', '==', 'Scheduled')
      .limit(MAX_PROMOTIONS_PER_RUN);

    if (cleanClassId) {
      query = db
        .collection('meetings')
        .where('status', '==', 'Scheduled')
        .where('class_id', '==', cleanClassId)
        .limit(MAX_PROMOTIONS_PER_RUN);
    }

    const snap = await query.get();
    const nowMs = Date.now();

    const promoted: string[] = [];
    let skippedFuture = 0;
    let skippedNoPublishAt = 0;
    let skippedForbidden = 0;
    let skippedArchivedClass = 0;

    const batch = db.batch();
    let batchOps = 0;

    for (const doc of snap.docs) {
      const data = doc.data() || {};
      const meetingClassId = data.class_id as string | undefined;

      // Batas kepemilikan untuk GURU non-admin pada sweep global.
      if (!isCronCall && !isAdminCaller && callerUid) {
        if (!meetingClassId) {
          skippedForbidden++;
          continue;
        }
        // Periksa teacher_id kelas induk (cache sederhana per run).
        const classDoc = await db.collection('classes').doc(meetingClassId).get();
        const classData = classDoc.data() || {};
        if (!classDoc.exists || classData.teacher_id !== callerUid) {
          skippedForbidden++;
          continue;
        }
        if (classData.status === 'Archived') {
          skippedArchivedClass++;
          continue;
        }
      } else if (meetingClassId) {
        // Mode cron/admin tetap menghormati kelas Archived (tidak ikut dipublikasikan).
        const classDoc = await db.collection('classes').doc(meetingClassId).get();
        if (classDoc.exists && (classDoc.data() || {}).status === 'Archived') {
          skippedArchivedClass++;
          continue;
        }
      }
      void scopedTeacherId;

      const publishAtRaw = (data as Record<string, any>).publish_at;
      let publishAtMs: number | null = null;
      if (publishAtRaw && typeof publishAtRaw.toMillis === 'function') {
        publishAtMs = publishAtRaw.toMillis();
      } else if (publishAtRaw instanceof Date) {
        publishAtMs = publishAtRaw.getTime();
      } else if (typeof publishAtRaw === 'string') {
        const parsed = Date.parse(publishAtRaw);
        publishAtMs = Number.isNaN(parsed) ? null : parsed;
      }

      if (publishAtMs === null) {
        skippedNoPublishAt++;
        continue;
      }
      if (publishAtMs > nowMs) {
        skippedFuture++;
        continue;
      }

      batch.update(doc.ref, {
        status: 'Published',
        publish_at: null,
        updated_at: FieldValue.serverTimestamp(),
      });
      batchOps++;
      promoted.push(doc.id);
    }

    if (batchOps > 0) {
      await batch.commit();
    }

    return res.status(200).json({
      success: true,
      checked: snap.size,
      promoted,
      promotedCount: promoted.length,
      skippedFuture,
      skippedNoPublishAt,
      skippedForbidden,
      skippedArchivedClass,
      hasMore: snap.size >= MAX_PROMOTIONS_PER_RUN,
      message:
        promoted.length > 0
          ? `${promoted.length} pertemuan terjadwal berhasil dipublikasikan.`
          : 'Tidak ada pertemuan terjadwal yang jatuh tempo saat ini.',
    });
  } catch (err: any) {
    console.error('Error publish-meetings:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan server saat mempublikasikan pertemuan terjadwal.' });
  }
}
