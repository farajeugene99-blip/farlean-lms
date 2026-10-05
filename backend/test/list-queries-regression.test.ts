import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { setLogLevel } from '@firebase/firestore';
import * as fs from 'fs';
import * as path from 'path';

// Bungkam log internal gRPC Firestore agar tidak mencemari terminal output
setLogLevel('silent');

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

async function runListRegressionTests() {
  console.log('🚀 Memulai List Queries & Write Validation Regression Test Suite...');
  await setupDatabase();

  const realClassId = 'class_reg_list_01';
  const dummyClassId = 'default_class';
  const activeStudentUid = 'student_list_active_01';
  const pendingStudentUid = 'student_list_pending_01';
  const removedStudentUid = 'student_list_removed_01';
  const teacherUid = 'teacher_list_guru_01';

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();

    await adminDb.collection('classes').doc(realClassId).set({
      name: 'Kelas Regresi List',
      teacher_id: teacherUid,
    });

    await adminDb.collection('classes').doc(realClassId).collection('members').doc(activeStudentUid).set({
      status: 'active',
      account_type: 'MAHASISWA',
    });
    await adminDb.collection('classes').doc(realClassId).collection('members').doc(pendingStudentUid).set({
      status: 'pending',
      account_type: 'UMUM',
    });
    await adminDb.collection('classes').doc(realClassId).collection('members').doc(removedStudentUid).set({
      status: 'removed',
      account_type: 'MAHASISWA',
    });
    await adminDb.collection('classes').doc(realClassId).collection('members').doc(teacherUid).set({
      status: 'active',
      account_type: 'DOSEN',
    });

    await adminDb.collection('meetings').doc('meet_reg_pub_1').set({
      class_id: realClassId,
      number: 1,
      title: 'Pertemuan 1 Published',
      status: 'Published',
    });
    await adminDb.collection('meetings').doc('meet_reg_draft_1').set({
      class_id: realClassId,
      number: 2,
      title: 'Pertemuan 2 Draft',
      status: 'Draft',
    });

    await adminDb.collection('manual_books').doc('book_reg_1').set({
      class_id: realClassId,
      title: 'Buku Panduan Regresi',
      file_url: 'https://example.com/book.pdf',
      file_name: 'book.pdf',
      file_size: 1024,
    });
  });

  const activeStudentDb = testEnv
    .authenticatedContext(activeStudentUid, { email_verified: true, role: 'USER' })
    .firestore();

  const pendingStudentDb = testEnv
    .authenticatedContext(pendingStudentUid, { email_verified: true, role: 'USER' })
    .firestore();

  const removedStudentDb = testEnv
    .authenticatedContext(removedStudentUid, { email_verified: true, role: 'USER' })
    .firestore();

  const teacherDb = testEnv
    .authenticatedContext(teacherUid, { email_verified: true, role: 'GURU' })
    .firestore();

  let passed = 0;
  let failed = 0;

  async function test(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  [FAIL] ${name}`);
      console.error(`     Error: ${err.message || err}`);
      failed++;
    }
  }

  // 1. Query Meetings Varian Non-Staff
  await test('1. Siswa AKTIF dapat query list meetings Published di kelasnya', async () => {
    await assertSucceeds(
      activeStudentDb
        .collection('meetings')
        .where('class_id', '==', realClassId)
        .where('status', '==', 'Published')
        .get()
    );
  });

  // 2. Query Meetings Varian Staff
  await test('2. GURU dapat query list meetings (termasuk Draft) di kelasnya', async () => {
    await assertSucceeds(
      teacherDb
        .collection('meetings')
        .where('class_id', '==', realClassId)
        .get()
    );
  });

  // 3. Query Manual Books oleh Siswa Aktif
  await test('3. Siswa AKTIF dapat query list manual_books di kelasnya', async () => {
    await assertSucceeds(
      activeStudentDb
        .collection('manual_books')
        .where('class_id', '==', realClassId)
        .get()
    );
  });

  // 4. Query Manual Books oleh Guru
  await test('4. GURU dapat query list manual_books di kelasnya', async () => {
    await assertSucceeds(
      teacherDb
        .collection('manual_books')
        .where('class_id', '==', realClassId)
        .get()
    );
  });

  // 5. Query Meetings oleh Member Pending DITOLAK
  await test('5. Member PENDING DITOLAK saat query list meetings', async () => {
    await assertFails(
      pendingStudentDb
        .collection('meetings')
        .where('class_id', '==', realClassId)
        .where('status', '==', 'Published')
        .get()
    );
  });

  // 6. Query Meetings oleh Member Removed DITOLAK
  await test('6. Member REMOVED DITOLAK saat query list meetings', async () => {
    await assertFails(
      removedStudentDb
        .collection('meetings')
        .where('class_id', '==', realClassId)
        .where('status', '==', 'Published')
        .get()
    );
  });

  // 7. Query Meetings dengan placeholder default_class DITOLAK
  await test('7. Query list meetings dengan placeholder "default_class" DITOLAK', async () => {
    await assertFails(
      activeStudentDb
        .collection('meetings')
        .where('class_id', '==', dummyClassId)
        .where('status', '==', 'Published')
        .get()
    );
  });

  // 8. Query Manual Books dengan placeholder default_class DITOLAK
  await test('8. Query list manual_books dengan placeholder "default_class" DITOLAK', async () => {
    await assertFails(
      activeStudentDb
        .collection('manual_books')
        .where('class_id', '==', dummyClassId)
        .get()
    );
  });

  // 9. Validasi Tulis: GURU DIBLOKIR membuat meeting dengan status invalid
  await test('9. GURU DIBLOKIR membuat meeting jika status bukan Draft/Published/Archived', async () => {
    await assertFails(
      teacherDb.collection('meetings').doc('meet_invalid_status').set({
        class_id: realClassId,
        number: 3,
        title: 'Meeting Salah',
        status: 'UnknownStatus',
      })
    );
  });

  // 10. Validasi Tulis: GURU DIBLOKIR membuat meeting tanpa class_id
  await test('10. GURU DIBLOKIR membuat meeting tanpa class_id yang valid', async () => {
    await assertFails(
      teacherDb.collection('meetings').doc('meet_no_class').set({
        class_id: '',
        number: 4,
        title: 'Meeting Tanpa Kelas',
        status: 'Draft',
      })
    );
  });

  // 11. Validasi Tulis: GURU DIBLOKIR membuat manual_book tanpa file_url
  await test('11. GURU DIBLOKIR membuat manual_book tanpa file_url valid', async () => {
    await assertFails(
      teacherDb.collection('manual_books').doc('book_no_url').set({
        class_id: realClassId,
        title: 'Book Tanpa URL',
        file_url: '',
      })
    );
  });

  // 12. Validasi Tulis: GURU DIIZINKAN membuat meeting dengan data sah
  await test('12. GURU DIIZINKAN membuat meeting dengan data yang valid', async () => {
    await assertSucceeds(
      teacherDb.collection('meetings').doc('meet_valid_new').set({
        class_id: realClassId,
        number: 5,
        title: 'Meeting Valid Guru',
        status: 'Draft',
      })
    );
  });

  await testEnv.cleanup();

  console.log(`\n========================================`);
  console.log(`LIST REGRESSION TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runListRegressionTests().catch((e) => {
  console.error('Fatal list regression test error:', e);
  process.exit(1);
});
