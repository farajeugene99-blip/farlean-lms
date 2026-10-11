import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue, WriteBatch } from 'firebase-admin/firestore';

// 1. Safety Guard: Require emulator or explicit production override
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_MIGRATION === 'true';
const isDryRun = process.env.DRY_RUN === 'true' || process.argv.includes('--dry-run');

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip backfill balasan HANYA boleh dijalankan pada Firebase Emulator');
  console.error('atau dengan environment variable ALLOW_PRODUCTION_MIGRATION=true.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

export async function runReplyBackfill() {
  console.log('🔄 ========================================================');
  console.log(`📦 MEMULAI IDEMPOTENT BACKFILL SCRIPT: REPLY STATUS ${isDryRun ? '(DRY-RUN MODE)' : '(LIVE MODE)'}`);
  console.log(`Target: Firestore (${process.env.FIRESTORE_EMULATOR_HOST || 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  let totalDiscussionsChecked = 0;
  let totalRepliesChecked = 0;
  let totalRepliesNeedingBackfill = 0;
  let totalRepliesBackfilled = 0;

  // Baca seluruh diskusi
  const discussionsSnap = await db.collection('discussions').get();
  totalDiscussionsChecked = discussionsSnap.size;

  let currentBatch: WriteBatch = db.batch();
  let batchOpsCount = 0;
  const BATCH_LIMIT = 500;

  for (const discDoc of discussionsSnap.docs) {
    const repliesSnap = await discDoc.ref.collection('replies').get();
    totalRepliesChecked += repliesSnap.size;

    for (const replyDoc of repliesSnap.docs) {
      const data = replyDoc.data();
      if (!data.status) {
        totalRepliesNeedingBackfill++;
        if (!isDryRun) {
          currentBatch.update(replyDoc.ref, {
            status: 'ACTIVE',
            updated_at: data.updated_at || FieldValue.serverTimestamp(),
          });
          batchOpsCount++;
          totalRepliesBackfilled++;

          if (batchOpsCount >= BATCH_LIMIT) {
            await currentBatch.commit();
            console.log(`  [BATCH COMMITTED] ${batchOpsCount} balasan berhasil di-backfill.`);
            currentBatch = db.batch();
            batchOpsCount = 0;
          }
        }
      }
    }
  }

  // Commit sisa batch jika ada
  if (!isDryRun && batchOpsCount > 0) {
    await currentBatch.commit();
    console.log(`  [FINAL BATCH COMMITTED] ${batchOpsCount} balasan berhasil di-backfill.`);
  }

  console.log('\n========================================================');
  console.log('🏁 HASIL BACKFILL BALASAN DISKUSI:');
  console.log(`- Mode                : ${isDryRun ? 'DRY RUN (Pemeriksaan saja)' : 'LIVE EXECUTION'}`);
  console.log(`- Diskusi Diperiksa   : ${totalDiscussionsChecked}`);
  console.log(`- Balasan Diperiksa   : ${totalRepliesChecked}`);
  console.log(`- Balasan Butuh Status: ${totalRepliesNeedingBackfill}`);
  console.log(`- Balasan Diperbarui  : ${totalRepliesBackfilled}`);
  console.log('========================================================\n');
}

if (require.main === module) {
  runReplyBackfill()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Fatal backfill error:', err);
      process.exit(1);
    });
}
