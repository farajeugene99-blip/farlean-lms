import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getFirestore, WriteBatch } from 'firebase-admin/firestore';

/**
 * Skrip Rollback Darurat: Mengembalikan key_snapshot dari evaluation/summary ke dokumen induk attempts/{id}
 *
 * PERINGATAN:
 * Menjalankan skrip ini akan mengembalikan seluruh kunci jawaban ke dokumen induk attempts/{id},
 * yang berarti siswa akan dapat membaca kembali kunci jawaban pasca-grading.
 * Hanya gunakan skrip ini jika terjadi malfungsi kritis pada integrasi evaluation.
 *
 * Guard Keamanan:
 * - Wajib dijalankan pada Emulator ATAU menyertakan ALLOW_PRODUCTION_ATTEMPT_REVERT=true.
 * - Default: DRY-RUN aktif (tidak mengubah data). Sertakan flag --live untuk eksekusi nyata.
 */

const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_ATTEMPT_REVERT === 'true';
const isLive = process.argv.includes('--live') || process.env.LIVE === 'true';
const isDryRun = !isLive;

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip revert evaluasi HANYA boleh dijalankan pada Firebase Emulator');
  console.error('atau dengan environment variable ALLOW_PRODUCTION_ATTEMPT_REVERT=true.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined;

  if (process.env.FIREBASE_CLIENT_EMAIL && privateKey) {
    initializeApp({
      credential: cert({
        projectId,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey,
      }),
    });
  } else {
    initializeApp({ projectId });
  }
}

const db = getFirestore();

export async function runAttemptEvaluationRevert(options?: { live?: boolean }) {
  const live = options?.live ?? (process.argv.includes('--live') || process.env.LIVE === 'true');
  const isDryRun = !live;

  console.log('🔄 ========================================================');
  console.log(`⚠️ MEMULAI ROLLBACK ATTEMPT EVALUATION ${isDryRun ? '(DRY-RUN MODE)' : '(LIVE MODE)'}`);
  console.log(`Target: Firestore (${hasFirestoreEmulator ? process.env.FIRESTORE_EMULATOR_HOST : 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  let totalScanned = 0;
  let totalReverted = 0;
  let totalSkipped = 0;

  const BATCH_ATTEMPT_LIMIT = 250;
  let currentBatch: WriteBatch = db.batch();
  let batchOpsCount = 0;

  const attemptsSnap = await db
    .collection('attempts')
    .where('status', '==', 'graded')
    .get();

  totalScanned = attemptsSnap.size;

  for (const doc of attemptsSnap.docs) {
    const data = doc.data();

    // Jika parent sudah punya key_snapshot, lewati
    if (data.key_snapshot !== undefined && data.key_snapshot !== null) {
      totalSkipped++;
      continue;
    }

    const evalRef = doc.ref.collection('evaluation').doc('summary');
    const evalSnap = await evalRef.get();

    if (evalSnap.exists && evalSnap.data()?.key_snapshot) {
      if (!isDryRun) {
        currentBatch.update(doc.ref, {
          key_snapshot: evalSnap.data()!.key_snapshot,
        });
        batchOpsCount++;
        totalReverted++;

        if (batchOpsCount >= BATCH_ATTEMPT_LIMIT) {
          console.log(`💾 Melakukan commit batch revert (${batchOpsCount} operasi)...`);
          await currentBatch.commit();
          currentBatch = db.batch();
          batchOpsCount = 0;
        }
      } else {
        totalReverted++;
      }
    } else {
      totalSkipped++;
    }
  }

  if (!isDryRun && batchOpsCount > 0) {
    await currentBatch.commit();
  }

  console.log('\n========================================');
  console.log('📊 RINGKASAN HASIL REVERT EVALUASI:');
  console.log(`Total Attempt Graded Dipindai : ${totalScanned}`);
  console.log(`Attempt Berhasil Dikembalikan : ${totalReverted}`);
  console.log(`Attempt Dilewati              : ${totalSkipped}`);
  console.log('========================================\n');
}

if (require.main === module) {
  runAttemptEvaluationRevert().catch((e) => {
    console.error('Fatal revert execution error:', e);
    process.exit(1);
  });
}
