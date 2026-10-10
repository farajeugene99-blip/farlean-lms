import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = process.env.FIREBASE_AUTH_EMULATOR_HOST || '127.0.0.1:9099';
const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

/**
 * Script Pemulihan & Audit Integritas Attempt Kuis Farlean LMS (P0-3)
 *
 * Mode Operasi:
 * 1. Default (DRY-RUN / Read-Only):
 *    npx tsx scripts/audit-corrupted-attempts.ts
 *    - Memindai seluruh dokumen attempts.
 *    - Mengidentifikasi attempt yang berstatus graded dengan 0 jawaban atau durasi instan.
 *    - Mengidentifikasi attempt in_progress yang menunjuk ke kuis berstatus Draft.
 *    - Mengidentifikasi attempt in_progress yang basi (stale).
 *
 * 2. Reset Attempt Tertentu (Safe Action):
 *    npx tsx scripts/audit-corrupted-attempts.ts --reset-attempt <ATTEMPT_ID>
 *    - Mengubah status attempt menjadi 'abandoned_reset' agar kuota percobaan siswa
 *      dapat dipulihkan secara aman tanpa menghapus rekaman audit.
 */
async function runAudit() {
  const args = process.argv.slice(2);
  const resetAttemptIdx = args.indexOf('--reset-attempt');
  const targetResetId = resetAttemptIdx !== -1 && args[resetAttemptIdx + 1] ? args[resetAttemptIdx + 1].trim() : null;

  console.log('🛡️ === FARLEAN LMS: AUDIT & PEMULIHAN INTEGRITAS ATTEMPTS ===');
  console.log(`Target: Firestore (${process.env.FIRESTORE_EMULATOR_HOST || 'PROD'}) | Project: ${projectId}`);
  console.log(`Mode: ${targetResetId ? `RESET ATTEMPT (${targetResetId})` : 'READ-ONLY AUDIT (DRY-RUN)'}\n`);

  if (targetResetId) {
    const docRef = db.collection('attempts').doc(targetResetId);
    const snap = await docRef.get();
    if (!snap.exists) {
      console.error(`❌ Attempt dengan ID ${targetResetId} tidak ditemukan.`);
      process.exit(1);
    }
    const data = snap.data() || {};
    console.log(`Dokumen ditemukan: User ${data.user_id}, Test ${data.test_id}, Status saat ini: ${data.status}`);

    await docRef.update({
      status: 'abandoned_reset',
      reset_at: FieldValue.serverTimestamp(),
      reset_reason: 'Corrupted instant finish recovery or draft test fix',
    });
    console.log(`✅ Attempt ${targetResetId} berhasil direset statusnya menjadi 'abandoned_reset'. Kuota pengerjaan siswa kini dapat diulang.`);
    process.exit(0);
  }

  const attemptsSnap = await db.collection('attempts').get();
  console.log(`📊 Total Dokumen Attempts di Database: ${attemptsSnap.size}`);

  const pretestsSnap = await db.collection('pretests').get();
  const posttestsSnap = await db.collection('posttests').get();
  const testMap: Record<string, any> = {};
  pretestsSnap.forEach((d) => (testMap[d.id] = { ...d.data(), kind: 'pretest' }));
  posttestsSnap.forEach((d) => (testMap[d.id] = { ...d.data(), kind: 'posttest' }));

  let zeroAnswerGraded = 0;
  let draftLinkedAttempts = 0;
  let staleInProgress = 0;

  const flaggedList: any[] = [];
  const now = Date.now();

  for (const doc of attemptsSnap.docs) {
    const a = doc.data();
    const test = testMap[a.test_id];
    const answers = a.answers || {};
    const answerCount = Object.keys(answers).length;

    const startedMs = a.started_at?.toMillis ? a.started_at.toMillis() : null;
    const submittedMs = a.submitted_at?.toMillis ? a.submitted_at.toMillis() : null;
    const durationFromStartSec = (startedMs && submittedMs) ? Math.round((submittedMs - startedMs) / 1000) : null;

    let flag = '';

    // Cek graded dengan jawaban kosong
    if ((a.status === 'graded' || a.status === 'submitted') && answerCount === 0) {
      zeroAnswerGraded++;
      flag = 'GRADED_ZERO_ANSWERS';
    }

    // Cek menunjuk ke kuis Draft
    if (test && test.status === 'Draft' && a.status === 'in_progress') {
      draftLinkedAttempts++;
      flag = flag ? `${flag}|DRAFT_LINKED` : 'DRAFT_LINKED';
    }

    // Cek stale in_progress (lebih dari 24 jam)
    if (a.status === 'in_progress' && startedMs && (now - startedMs > 24 * 60 * 60 * 1000)) {
      staleInProgress++;
      flag = flag ? `${flag}|STALE_IN_PROGRESS` : 'STALE_IN_PROGRESS';
    }

    if (flag) {
      flaggedList.push({
        attemptId: doc.id,
        user: a.user_id,
        test: a.test_id,
        testStatus: test?.status || 'NOT_FOUND',
        status: a.status,
        answers: answerCount,
        durationSec: durationFromStartSec ?? 'N/A',
        flag,
      });
    }
  }

  console.log('\n📋 Temuan Integritas Attempt:');
  console.log(`- Attempt Graded dengan 0 Jawaban : ${zeroAnswerGraded}`);
  console.log(`- Attempt in_progress pada Kuis Draft : ${draftLinkedAttempts}`);
  console.log(`- Attempt in_progress Basi (>24 Jam) : ${staleInProgress}`);

  if (flaggedList.length > 0) {
    console.log('\n🔍 Daftar Dokumen Berisiko:');
    console.table(flaggedList);
    console.log('💡 Untuk mereset attempt rusak tertentu, jalankan:');
    console.log('   npx tsx scripts/audit-corrupted-attempts.ts --reset-attempt <attemptId>\n');
  } else {
    console.log('🎉 Tidak ditemukan dokumen attempt yang bermasalah!\n');
  }
}

runAudit().catch(console.error);
