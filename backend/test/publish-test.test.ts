import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import publishTestHandler from '../api/publish-test';
import { setTokenVerifier, resetTokenVerifier } from '../lib/firebaseAdmin';

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIREBASE_PROJECT_ID = 'farlean-lms-test';

if (!getApps().length) {
  initializeApp({ projectId: 'farlean-lms-test' });
}

const db = getFirestore();

interface MockResponse {
  statusCode: number;
  jsonData: any;
  headers: Record<string, string>;
  status(code: number): MockResponse;
  json(data: any): MockResponse;
  setHeader(key: string, value: string): MockResponse;
  end(): MockResponse;
}

function createMockRes(): MockResponse {
  return {
    statusCode: 200,
    jsonData: null,
    headers: {},
    status(code: number) {
      this.statusCode = code;
      return this;
    },
    json(data: any) {
      this.jsonData = data;
      return this;
    },
    setHeader(key: string, value: string) {
      this.headers[key.toLowerCase()] = value;
      return this;
    },
    end() {
      return this;
    },
  };
}

async function runPublishTestTests() {
  console.log('🚀 Memulai Test Suite /api/publish-test...');

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

  const teacherUid = 'guru_publish_owner_' + Date.now();
  const otherTeacherUid = 'guru_publish_other_' + Date.now();
  const studentUid = 'student_publish_test_' + Date.now();
  const testClassId = 'class_publish_test_' + Date.now();
  const emptyPretestId = 'pretest_empty_' + Date.now();
  const populatedPretestId = 'pretest_populated_' + Date.now();

  // Setup Class
  await db.collection('classes').doc(testClassId).set({
    name: 'Kelas Publikasi Soal',
    teacher_id: teacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });

  // Setup Empty Pretest (Status Draft, 0 soal)
  await db.collection('pretests').doc(emptyPretestId).set({
    title: 'Pretest Tanpa Soal',
    class_id: testClassId,
    status: 'Draft',
    duration: 15,
    created_at: FieldValue.serverTimestamp(),
  });

  // Setup Populated Pretest (Status Draft, 1 soal & 1 kunci)
  await db.collection('pretests').doc(populatedPretestId).set({
    title: 'Pretest Dengan Soal',
    class_id: testClassId,
    status: 'Draft',
    duration: 15,
    created_at: FieldValue.serverTimestamp(),
  });

  const qid = 'q_pub_1';
  await db.collection('pretests').doc(populatedPretestId).collection('questions').doc(qid).set({
    text: 'Soal 1',
    options: ['A', 'B'],
    points: 10,
    deleted: false,
  });
  await db.collection('answer_keys').doc(populatedPretestId).collection('items').doc(qid).set({
    qid,
    correct_option: 0,
    points: 10,
    deleted: false,
  });

  // 1. Menolak role USER
  await test('1. Menolak pengguna dengan role USER (403)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'student@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: populatedPretestId, status: 'Published' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 2. Menolak GURU non-owner
  await test('2. Menolak GURU non-owner (403)', async () => {
    setTokenVerifier(async () => ({
      uid: otherTeacherUid,
      email: 'other@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: populatedPretestId, status: 'Published' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 3. Menolak mem-publish kuis tanpa soal (0 soal aktif)
  await test('3. Menolak publikasi kuis jika belum memiliki soal aktif (400)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: emptyPretestId, status: 'Published' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('belum memiliki soal aktif')) {
      throw new Error(`Expected empty questions error, got: ${res.jsonData?.error}`);
    }
  });

  // 4. Berhasil mem-publish kuis dengan soal aktif
  await test('4. Berhasil mem-publish kuis dengan minimal 1 soal aktif (200)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: populatedPretestId, status: 'Published' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (res.jsonData?.status !== 'Published') throw new Error(`Expected status Published, got ${res.jsonData?.status}`);

    // Verifikasi di Firestore
    const testDoc = await db.collection('pretests').doc(populatedPretestId).get();
    if (testDoc.data()?.status !== 'Published') throw new Error('Firestore document was not updated to Published');
  });

  // 5. Menolak unpublish ke Draft jika sudah ada attempt
  await test('5. Menolak unpublish ke Draft jika sudah ada attempt pengerjaan siswa (400)', async () => {
    // Buat attempt di populatedPretestId
    await db.collection('attempts').doc('attempt_publish_test').set({
      test_id: populatedPretestId,
      user_id: studentUid,
      class_id: testClassId,
      status: 'in_progress',
      started_at: FieldValue.serverTimestamp(),
    });

    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: populatedPretestId, status: 'Draft' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('tidak dapat dikembalikan ke status Draft')) {
      throw new Error(`Expected attempt unpublish error, got: ${res.jsonData?.error}`);
    }
  });

  // 6. Mengizinkan transisi ke Archived saat ada attempt
  await test('6. Mengizinkan pengubahan status ke Archived saat ada attempt (200)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { testId: populatedPretestId, status: 'Archived' },
    };
    const res = createMockRes();
    await publishTestHandler(req, res as any);
    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData?.status !== 'Archived') throw new Error(`Expected status Archived, got ${res.jsonData?.status}`);
  });

  resetTokenVerifier();

  console.log(`\n========================================`);
  console.log(`PUBLISH-TEST TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runPublishTestTests().catch((e) => {
  console.error('Fatal publish-test error:', e);
  process.exit(1);
});
