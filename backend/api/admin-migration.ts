import type { VercelRequest, VercelResponse } from '@vercel/node';
import { timingSafeEqual } from 'crypto';
import { db, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

function safeCompare(a: string, b: string): boolean {
  if (!a || !b) return false;
  const bufA = Buffer.from(a);
  const bufB = Buffer.from(b);
  if (bufA.length !== bufB.length) return false;
  return timingSafeEqual(bufA, bufB);
}

/**
 * Endpoint Administratif Khusus Fase 1.5:
 * - Terproteksi penuh oleh CRON_SECRET menggunakan timingSafeEqual.
 * - Menjalankan pemeriksaan data produksi, dump kritis, dan isolasi evaluasi
 *   menggunakan kredensial resmi Firebase Admin SDK di runtime Vercel Cloud.
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  const cronSecret = process.env.CRON_SECRET || '';
  const authHeader = (req.headers.authorization as string | undefined) || '';
  const providedBearer = authHeader.startsWith('Bearer ') ? authHeader.slice(7).trim() : '';

  if (!cronSecret || !safeCompare(providedBearer, cronSecret)) {
    return res.status(401).json({ error: 'Akses administratif ditolak: CRON_SECRET tidak valid.' });
  }

  const action = (req.query.action || req.body?.action) as string | undefined;

  try {
    // 1. Aksi Count / Ringkasan Data
    if (action === 'count') {
      const attemptsCount = (await db.collection('attempts').count().get()).data().count;
      const discussionsCount = (await db.collection('discussions').count().get()).data().count;
      const classesCount = (await db.collection('classes').count().get()).data().count;
      const pretestsCount = (await db.collection('pretests').count().get()).data().count;
      const posttestsCount = (await db.collection('posttests').count().get()).data().count;
      const meetingsCount = (await db.collection('meetings').count().get()).data().count;

      return res.status(200).json({
        success: true,
        counts: {
          attempts: attemptsCount,
          discussions: discussionsCount,
          classes: classesCount,
          pretests: pretestsCount,
          posttests: posttestsCount,
          meetings: meetingsCount,
        },
      });
    }

    // 2. Aksi Dump Kritis (Mengembalikan seluruh dokumen attempts & discussions)
    if (action === 'dump') {
      const attemptsSnap = await db.collection('attempts').get();
      const attempts = attemptsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

      const discussionsSnap = await db.collection('discussions').get();
      const discussions = discussionsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

      return res.status(200).json({
        success: true,
        counts: {
          attempts: attempts.length,
          discussions: discussions.length,
        },
        data: {
          attempts,
          discussions,
        },
      });
    }

    // 3. Aksi Isolasi Evaluasi (Dry-Run vs Live)
    if (action === 'isolate-dry-run' || action === 'isolate-live') {
      const isLive = action === 'isolate-live';

      let totalScanned = 0;
      let totalNeedingIsolation = 0;
      let totalIsolated = 0;
      let totalAlreadyClean = 0;
      let totalEmptyClassIdRecovered = 0;
      let totalErrors = 0;

      const BATCH_ATTEMPT_LIMIT = 250;
      let currentBatch = db.batch();
      let batchOpsCount = 0;

      const attemptsSnap = await db
        .collection('attempts')
        .where('status', '==', 'graded')
        .get();

      totalScanned = attemptsSnap.size;

      for (const doc of attemptsSnap.docs) {
        const data = doc.data();
        const hasKeySnapshot = data.key_snapshot !== undefined && data.key_snapshot !== null;

        if (!hasKeySnapshot) {
          totalAlreadyClean++;
          continue;
        }

        totalNeedingIsolation++;

        let classId = data.class_id || '';
        if (!classId) {
          totalEmptyClassIdRecovered++;
        }

        try {
          const evalRef = doc.ref.collection('evaluation').doc('summary');
          const evalSnap = await evalRef.get();

          if (isLive) {
            if (!evalSnap.exists) {
              if (!classId && data.test_id) {
                try {
                  const testDoc = await db.collection('pretests').doc(data.test_id).get();
                  if (testDoc.exists) {
                    classId = testDoc.data()?.class_id || '';
                  } else {
                    const postDoc = await db.collection('posttests').doc(data.test_id).get();
                    if (postDoc.exists) classId = postDoc.data()?.class_id || '';
                  }
                } catch (_) {}
              }

              currentBatch.set(evalRef, {
                class_id: classId,
                test_id: data.test_id || '',
                user_id: data.user_id || '',
                key_snapshot: data.key_snapshot,
                points_earned: data.points_earned ?? 0,
                total_points: data.total_points ?? 0,
                final_score: data.score ?? 0,
                graded_at: data.graded_at || FieldValue.serverTimestamp(),
              });
              batchOpsCount++;
            }

            currentBatch.update(doc.ref, {
              key_snapshot: FieldValue.delete(),
            });
            batchOpsCount++;

            totalIsolated++;

            if (batchOpsCount >= BATCH_ATTEMPT_LIMIT * 2) {
              await currentBatch.commit();
              currentBatch = db.batch();
              batchOpsCount = 0;
            }
          }
        } catch (err: any) {
          console.error(`Error processing attempt ${doc.id}:`, err);
          totalErrors++;
          if (totalErrors > 10) break;
        }
      }

      if (isLive && batchOpsCount > 0) {
        await currentBatch.commit();
      }

      return res.status(200).json({
        success: true,
        mode: isLive ? 'live' : 'dry-run',
        totalScanned,
        totalNeedingIsolation,
        totalEmptyClassIdRecovered,
        totalIsolated: isLive ? totalIsolated : 0,
        totalAlreadyClean,
        totalErrors,
      });
    }

    return res.status(400).json({ error: 'Aksi tidak dikenal. Pilihan: count, dump, isolate-dry-run, isolate-live' });
  } catch (err: any) {
    console.error('Error in admin-migration handler:', err);
    return res.status(500).json({ error: err.message || 'Terjadi kesalahan server.' });
  }
}
