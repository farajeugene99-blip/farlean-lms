import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import * as fs from 'fs';
import * as path from 'path';

// Pastikan terikat ke emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_PROJECT_ID = 'farlean-lms-test';
process.env.ALLOW_PRODUCTION_ATTEMPT_ISOLATION = 'true';
process.env.ALLOW_PRODUCTION_ATTEMPT_REVERT = 'true';
process.env.ALLOW_PRODUCTION_DUMP = 'true';

if (!getApps().length) {
  initializeApp({ projectId: 'farlean-lms-test' });
}

const db = getFirestore();

// Import runners
import { runAttemptEvaluationIsolation } from '../scripts/isolate-attempt-evaluations';
import { runAttemptEvaluationRevert } from '../scripts/revert-attempt-evaluations';
import { runCriticalDump } from '../scripts/dump-critical-collections';

async function runMigrationTests() {
  console.log('🧪 Memulai Uji Skrip Migrasi (Isolate, Revert, Dump) di Emulator...');

  // 1. Seed data uji
  const seedValidId = 'att_seed_valid_01';
  const seedEmptyClassId = 'att_seed_empty_class_02';
  const seedInProgressId = 'att_seed_inprogress_03';
  const recoverTestId = 'pretest_recover_01';

  await db.collection('pretests').doc(recoverTestId).set({
    class_id: 'class_recovered_from_test',
    title: 'Pretest Pemulihan',
    status: 'Published',
  });

  await db.collection('attempts').doc(seedValidId).set({
    user_id: 'user_seed_01',
    class_id: 'class_seed_01',
    test_id: recoverTestId,
    status: 'graded',
    score: 80,
    points_earned: 8,
    total_points: 10,
    key_snapshot: { q1: { correct_option: 0, points: 10 } },
  });

  await db.collection('attempts').doc(seedEmptyClassId).set({
    user_id: 'user_seed_02',
    class_id: '', // Empty class_id to test recovery
    test_id: recoverTestId,
    status: 'graded',
    score: 90,
    points_earned: 9,
    total_points: 10,
    key_snapshot: { q1: { correct_option: 1, points: 10 } },
  });

  await db.collection('attempts').doc(seedInProgressId).set({
    user_id: 'user_seed_03',
    class_id: 'class_seed_01',
    test_id: recoverTestId,
    status: 'in_progress',
    score: null,
  });

  console.log('✅ Seed data migrasi berhasil disiapkan.');

  // 2. Jalankan isolate-attempt-evaluations (Dry-Run)
  console.log('\n--- UJI 1: Isolate Dry-Run ---');
  await runAttemptEvaluationIsolation({ live: false });

  // Verifikasi dry-run tidak mengubah database
  let validDoc = await db.collection('attempts').doc(seedValidId).get();
  if (validDoc.data()?.key_snapshot === undefined) {
    throw new Error('FAIL: Dry-run tidak boleh menghapus key_snapshot dari parent!');
  }
  let evalDoc = await db.collection('attempts').doc(seedValidId).collection('evaluation').doc('summary').get();
  if (evalDoc.exists) {
    throw new Error('FAIL: Dry-run tidak boleh menulis evaluation/summary!');
  }
  console.log('✅ PASS: Dry-Run berhasil diverifikasi (database tidak berubah).');

  // 3. Jalankan isolate-attempt-evaluations (Live-Emulator)
  console.log('\n--- UJI 2: Isolate Live-Emulator ---');
  await runAttemptEvaluationIsolation({ live: true });

  validDoc = await db.collection('attempts').doc(seedValidId).get();
  if (validDoc.data()?.key_snapshot !== undefined) {
    throw new Error('FAIL: Live isolate harus menghapus key_snapshot dari parent!');
  }
  evalDoc = await db.collection('attempts').doc(seedValidId).collection('evaluation').doc('summary').get();
  if (!evalDoc.exists || evalDoc.data()?.class_id !== 'class_seed_01') {
    throw new Error('FAIL: evaluation/summary harus ada dengan class_id class_seed_01!');
  }

  // Cek pemulihan class_id kosong
  const emptyClassDoc = await db.collection('attempts').doc(seedEmptyClassId).collection('evaluation').doc('summary').get();
  if (!emptyClassDoc.exists || emptyClassDoc.data()?.class_id !== 'class_recovered_from_test') {
    throw new Error(`FAIL: class_id kosong harus dipulihkan dari test! Got: ${emptyClassDoc.data()?.class_id}`);
  }
  console.log('✅ PASS: Live Isolate berhasil! (parent bersih, evaluation terisolasi, class_id kosong dipulihkan).');

  // 4. Jalankan revert-attempt-evaluations (Dry-Run)
  console.log('\n--- UJI 3: Revert Dry-Run ---');
  await runAttemptEvaluationRevert({ live: false });
  validDoc = await db.collection('attempts').doc(seedValidId).get();
  if (validDoc.data()?.key_snapshot !== undefined) {
    throw new Error('FAIL: Revert dry-run tidak boleh mengembalikan key_snapshot ke parent!');
  }
  console.log('✅ PASS: Revert Dry-Run diverifikasi.');

  // 5. Jalankan revert-attempt-evaluations (Live-Emulator)
  console.log('\n--- UJI 4: Revert Live-Emulator ---');
  await runAttemptEvaluationRevert({ live: true });
  validDoc = await db.collection('attempts').doc(seedValidId).get();
  if (validDoc.data()?.key_snapshot === undefined) {
    throw new Error('FAIL: Revert live harus mengembalikan key_snapshot ke parent!');
  }
  console.log('✅ PASS: Revert Live berhasil! (key_snapshot kembali ke parent doc).');

  // 6. Jalankan dump-critical-collections
  console.log('\n--- UJI 5: Critical Dump ---');
  await runCriticalDump();
  const dumpDir = path.resolve(__dirname, '../.dump');
  const attemptsDumpPath = path.join(dumpDir, 'attempts-backup.json');
  if (!fs.existsSync(attemptsDumpPath)) {
    throw new Error('FAIL: File dump attempts tidak ditemukan!');
  }
  const dumpContent = JSON.parse(fs.readFileSync(attemptsDumpPath, 'utf8'));
  console.log(`✅ PASS: Critical dump berhasil! Total attempts di-dump: ${dumpContent.length}`);

  // Cleanup .dump folder setelah uji
  fs.rmSync(dumpDir, { recursive: true, force: true });
  console.log('🧹 Cleanup folder .dump selesai.');

  console.log('\n🎉 SELURUH SKRIP MIGRASI (ISOLATE, REVERT, DUMP) 100% SUKSES DAN TERVERIFIKASI DI EMULATOR!\n');
}

runMigrationTests().catch((e) => {
  console.error('Fatal migration test error:', e);
  process.exit(1);
});
