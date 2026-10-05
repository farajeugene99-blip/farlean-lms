// Set emulator host env sebelum import firebaseAdmin
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIREBASE_PROJECT_ID = 'farlean-lms-test';

import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';
import { serverTimestamp } from 'firebase/firestore';

let testEnv: RulesTestEnvironment;

async function setupDatabase() {
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  testEnv = await initializeTestEnvironment({
    projectId: 'farlean-lms-test',
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

async function runTestingAccountsTests() {
  console.log('🚀 Memulai Testing Accounts Automated Test Suite (Self-Contained)...');
  await setupDatabase();
  const { bootstrapUser } = await import('../lib/bootstrapUser');

  let passed = 0;
  let failed = 0;

  async function test(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message || err}`);
      failed++;
    }
  }

  // Identitas unik terisolasi untuk suite ini (tidak tabrakan dengan test lain)
  const studentUid = 'tqa_student_01';
  const teacherUid = 'tqa_teacher_01';
  const generalUid = 'tqa_general_01';
  const unverifiedUid = 'tqa_unverified_01';
  const removedUid = 'tqa_removed_01';
  const classId = 'tqa_class_isolated_01';

  // Seed data lokal mandiri (Self-Contained)
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();

    // 1. Inisialisasi Profil via bootstrapUser (menguji logika produksi langsung)
    await bootstrapUser({
      uid: studentUid,
      email: 'testing.student@farlean.edu',
      emailVerified: true,
      name: 'Test Student',
      initialRole: 'USER',
    });

    await bootstrapUser({
      uid: teacherUid,
      email: 'testing.teacher@dosen.farlean.edu',
      emailVerified: true,
      name: 'Test Teacher',
      initialRole: 'GURU',
    });

    await bootstrapUser({
      uid: generalUid,
      email: 'testing.user@example.com',
      emailVerified: true,
      name: 'Test General User',
      initialRole: 'USER',
    });

    await bootstrapUser({
      uid: unverifiedUid,
      email: 'testing.unverified@example.com',
      emailVerified: false,
      name: 'Test Unverified User',
      initialRole: 'USER',
    });

    await bootstrapUser({
      uid: removedUid,
      email: 'testing.removed@farlean.edu',
      emailVerified: true,
      name: 'Test Removed Student',
      initialRole: 'USER',
    });

    // 2. Buat Kelas Terisolasi
    await adminDb.collection('classes').doc(classId).set({
      name: 'Kelas QA Terisolasi',
      teacher_id: teacherUid,
    });

    // 3. Pasang Membership
    await adminDb.collection('classes').doc(classId).collection('members').doc(studentUid).set({
      display_name: 'Test Student',
      status: 'active',
      account_type: 'MAHASISWA',
    });

    await adminDb.collection('classes').doc(classId).collection('members').doc(teacherUid).set({
      display_name: 'Test Teacher',
      status: 'active',
      account_type: 'DOSEN',
    });

    await adminDb.collection('classes').doc(classId).collection('members').doc(generalUid).set({
      display_name: 'Test General User',
      status: 'pending',
      account_type: 'UMUM',
    });

    await adminDb.collection('classes').doc(classId).collection('members').doc(removedUid).set({
      display_name: 'Test Removed Student',
      status: 'removed',
      account_type: 'MAHASISWA',
    });

    // 4. Buat Materi Published & Draft
    await adminDb.collection('materials').doc('tqa_mat_published').set({
      class_id: classId,
      title: 'Materi Published QA',
      status: 'Published',
    });
    await adminDb.collection('materials').doc('tqa_mat_draft').set({
      class_id: classId,
      title: 'Materi Draft QA',
      status: 'Draft',
    });

    // 5. Buat Pretest & Kunci Jawaban
    await adminDb.collection('pretests').doc('tqa_pretest_01').set({
      class_id: classId,
      title: 'Pretest QA',
      status: 'Published',
    });
    await adminDb.collection('answer_keys').doc('tqa_pretest_01').collection('items').doc('q1').set({
      correct_option: 1,
      points: 100,
    });
  });

  // Client Contexts
  const studentDb = testEnv
    .authenticatedContext(studentUid, { email_verified: true, role: 'USER' })
    .firestore();

  const teacherDb = testEnv
    .authenticatedContext(teacherUid, { email_verified: true, role: 'GURU' })
    .firestore();

  const generalDb = testEnv
    .authenticatedContext(generalUid, { email_verified: true, role: 'USER' })
    .firestore();

  const unverifiedDb = testEnv
    .authenticatedContext(unverifiedUid, { email_verified: false, role: 'USER' })
    .firestore();

  const removedDb = testEnv
    .authenticatedContext(removedUid, { email_verified: true, role: 'USER' })
    .firestore();

  // Context Khusus Stale Claim: User teacher tetapi token membawa role lama 'USER'
  const staleTeacherDb = testEnv
    .authenticatedContext(teacherUid, { email_verified: true, role: 'USER' })
    .firestore();

  // ============================================================================
  // PENGUJIAN 1: PEMETAAN DOMAIN DARI BOOTSTRAPUSER PRODUKSI
  // ============================================================================
  await test('1. bootstrapUser memetakan domain farlean.edu ke MAHASISWA dan dosen.farlean.edu ke DOSEN', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const adminDb = context.firestore();
      const sDoc = await adminDb.collection('users').doc(studentUid).get();
      const tDoc = await adminDb.collection('users').doc(teacherUid).get();
      const gDoc = await adminDb.collection('users').doc(generalUid).get();
      const uDoc = await adminDb.collection('users').doc(unverifiedUid).get();

      if (sDoc.data()?.account_type !== 'MAHASISWA') throw new Error('Student account_type must be MAHASISWA');
      if (tDoc.data()?.account_type !== 'DOSEN') throw new Error('Teacher account_type must be DOSEN');
      if (gDoc.data()?.account_type !== 'UMUM') throw new Error('General user account_type must be UMUM');
      if (uDoc.data()?.account_type !== 'UMUM') throw new Error('Unverified user must stay UMUM until verified');
    });
  });

  // ============================================================================
  // PENGUJIAN 2: SKENARIO UNVERIFIED USER
  // ============================================================================
  await test('2. Skenario Unverified: User dengan email belum diverifikasi DIBLOKIR membaca kelas atau materi', async () => {
    // Ditolak membaca materi
    await assertFails(unverifiedDb.collection('materials').doc('tqa_mat_published').get());
    // Ditolak membaca kelas
    await assertFails(unverifiedDb.collection('classes').doc(classId).get());
  });

  // ============================================================================
  // PENGUJIAN 3: SKENARIO REMOVED USER
  // ============================================================================
  await test('3. Skenario Removed: Siswa yang dikeluarkan (status: removed) DIBLOKIR membaca konten kelas', async () => {
    await assertFails(removedDb.collection('materials').doc('tqa_mat_published').get());
    await assertFails(removedDb.collection('pretests').doc('tqa_pretest_01').get());
  });

  await test('4. Skenario Removed: Siswa yang dikeluarkan DIBLOKIR membuat attempt baru di kelas tersebut', async () => {
    await assertFails(
      removedDb.collection('attempts').doc('tqa_att_removed_illegal').set({
        user_id: removedUid,
        class_id: classId,
        test_id: 'tqa_pretest_01',
        status: 'in_progress',
        score: null,
        started_at: serverTimestamp(),
      })
    );
  });

  // ============================================================================
  // PENGUJIAN 4: SKENARIO STALE CLAIMS
  // ============================================================================
  await test('5. Skenario Stale Claims: Token lama sebelum refresh klaim (role: USER) DITOLAK membuat materi guru', async () => {
    // Mencoba menulis materi dengan token lama (claim role: USER) -> DITOLAK!
    await assertFails(
      staleTeacherDb.collection('materials').doc('tqa_mat_stale_fail').set({
        class_id: classId,
        title: 'Materi Stale',
        status: 'Draft',
      })
    );
  });

  await test('6. Skenario Fresh Claims: Token baru dengan klaim role GURU DIIZINKAN membuat materi guru', async () => {
    // Token baru yang membawa role: GURU -> DIIZINKAN!
    await assertSucceeds(
      teacherDb.collection('materials').doc('tqa_mat_fresh_ok').set({
        class_id: classId,
        title: 'Materi Fresh Claim',
        status: 'Draft',
      })
    );
  });

  // ============================================================================
  // PENGUJIAN 5: SKENARIO STUDENT & GENERAL
  // ============================================================================
  await test('7. TEST STUDENT aktif dapat membaca Materi Published, ditolak membaca Draft & answer_keys', async () => {
    await assertSucceeds(studentDb.collection('materials').doc('tqa_mat_published').get());
    await assertFails(studentDb.collection('materials').doc('tqa_mat_draft').get());
    await assertFails(studentDb.collection('answer_keys').doc('tqa_pretest_01').get());
  });

  await test('8. TEST GENERAL USER berstatus pending DIBLOKIR membaca materi restricted', async () => {
    await assertFails(generalDb.collection('materials').doc('tqa_mat_published').get());
  });

  // ============================================================================
  // CLEANUP MANDIRI (Self-Contained Cleanup)
  // ============================================================================
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    const uids = [studentUid, teacherUid, generalUid, unverifiedUid, removedUid];
    for (const uid of uids) {
      await adminDb.collection('users').doc(uid).delete();
    }
    const memSnap = await adminDb.collection('classes').doc(classId).collection('members').get();
    for (const d of memSnap.docs) await d.ref.delete();
    await adminDb.collection('classes').doc(classId).delete();
    await adminDb.collection('materials').doc('tqa_mat_published').delete();
    await adminDb.collection('materials').doc('tqa_mat_draft').delete();
    await adminDb.collection('materials').doc('tqa_mat_fresh_ok').delete();
    await adminDb.collection('pretests').doc('tqa_pretest_01').delete();
  });

  await testEnv.cleanup();

  console.log(`\n========================================`);
  console.log(`TESTING ACCOUNTS TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) process.exit(1);
}

runTestingAccountsTests().catch((e) => {
  console.error('Fatal testing accounts test error:', e);
  process.exit(1);
});
