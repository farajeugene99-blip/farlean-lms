import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue, WriteBatch } from 'firebase-admin/firestore';

/**
 * Skrip Migrasi Idempoten: Isolasi key_snapshot ke subkoleksi privat evaluation/summary
 *
 * Tujuan Keamanan (Zero-Leak Window Closure):
 * 1. Memindahkan field `key_snapshot` dari dokumen induk `attempts/{id}` ke `attempts/{id}/evaluation/summary`.
 * 2. Menghapus field `key_snapshot` dari dokumen induk menggunakan FieldValue.delete().
 * 3. Menjaga dokumen induk tetap dapat dibaca siswa untuk menampilkan skor tanpa membocorkan kunci jawaban.
 *
 * Guard Keamanan:
 * - Wajib dijalankan pada Emulator ATAU menyertakan ALLOW_PRODUCTION_ATTEMPT_ISOLATION=true.
 * - Default: DRY-RUN aktif (tidak mengubah data). Sertakan flag --live untuk eksekusi nyata.
 * - Pembagian batch: Maksimum 250 attempt (500 operasi Firestore) per WriteBatch commit.
 */

const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_ATTEMPT_ISOLATION === 'true';
const isLive = process.argv.includes('--live') || process.env.LIVE === 'true';
const isDryRun = !isLive;

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip isolasi evaluasi HANYA boleh dijalankan pada Firebase Emulator');
  console.error('atau dengan environment variable ALLOW_PRODUCTION_ATTEMPT_ISOLATION=true.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

export async function runAttemptEvaluationIsolation() {
  console.log('🔄 ========================================================');
  console.log(`📦 MEMULAI IDEMPOTENT ATTEMPT EVALUATION ISOLATION ${isDryRun ? '(DRY-RUN MODE)' : '(LIVE MODE)'}`);
  console.log(`Target: Firestore (${hasFirestoreEmulator ? process.env.FIRESTORE_EMULATOR_HOST : 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  let totalScanned = 0;
  let totalNeedingIsolation = 0;
  let totalIsolated = 0;
  let totalAlreadyClean = 0;
  let totalErrors = 0;

  const BATCH_ATTEMPT_LIMIT = 250; // 250 attempt * 2 ops = 500 operasi per batch (batas Firestore)
  let currentBatch: WriteBatch = db.batch();
  let batchOpsCount = 0;

  // Pindai attempt berstatus graded
  const attemptsSnap = await db
    .collection('attempts')
    .where('status', '==', 'graded')
    .get();

  totalScanned = attemptsSnap.size;
  console.log(`📋 Total attempt berstatus 'graded' ditemukan: ${totalScanned}`);

  for (const doc of attemptsSnap.docs) {
    const data = doc.data();
    const hasKeySnapshot = data.key_snapshot !== undefined && data.key_snapshot !== null;

    if (!hasKeySnapshot) {
      totalAlreadyClean++;
      continue;
    }

    totalNeedingIsolation++;

    try {
      const evalRef = doc.ref.collection('evaluation').doc('summary');
      const evalSnap = await evalRef.get();

      if (!isDryRun) {
        // Jika dokumen evaluation belum ada, salin snapshot ke subkoleksi
        if (!evalSnap.exists) {
          let classId = data.class_id || '';

          // Jika class_id kosong, coba pulihkan dari dokumen test
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

        // Hapus field key_snapshot dari dokumen induk attempts/{id}
        currentBatch.update(doc.ref, {
          key_snapshot: FieldValue.delete(),
        });
        batchOpsCount++;

        totalIsolated++;

        if (batchOpsCount >= BATCH_ATTEMPT_LIMIT * 2) {
          console.log(`💾 Melakukan commit batch (${batchOpsCount} operasi)...`);
          await currentBatch.commit();
          currentBatch = db.batch();
          batchOpsCount = 0;
        }
      }
    } catch (err: any) {
      console.error(`❌ Gagal memproses attempt ${doc.id}:`, err.message);
      totalErrors++;
      if (totalErrors > 10) {
        console.error('🚨 Terlalu banyak kegagalan (>10). Menghentikan eksekusi.');
        break;
      }
    }
  }

  // Commit sisa batch
  if (!isDryRun && batchOpsCount > 0) {
    console.log(`💾 Melakukan commit batch terakhir (${batchOpsCount} operasi)...`);
    await currentBatch.commit();
  }

  console.log('\n========================================');
  console.log('📊 RINGKASAN HASIL ISOLASI EVALUASI:');
  console.log(`Total Attempt Graded Dipindai : ${totalScanned}`);
  console.log(`Attempt Memuat key_snapshot   : ${totalNeedingIsolation}`);
  console.log(`Attempt Berhasil Diisolasi    : ${isDryRun ? `${totalNeedingIsolation} (simulasi)` : totalIsolated}`);
  console.log(`Attempt Sudah Bersih          : ${totalAlreadyClean}`);
  console.log(`Total Kesalahan               : ${totalErrors}`);
  console.log('========================================\n');

  if (isDryRun && totalNeedingIsolation > 0) {
    console.log('💡 Untuk menjalankan isolasi nyata, eksekusi dengan flag --live:');
    console.log('   npx tsx scripts/isolate-attempt-evaluations.ts --live\n');
  }
}

// Jalankan jika dieksekusi via CLI
if (require.main === module) {
  runAttemptEvaluationIsolation().catch((e) => {
    console.error('Fatal execution error:', e);
    process.exit(1);
  });
}
