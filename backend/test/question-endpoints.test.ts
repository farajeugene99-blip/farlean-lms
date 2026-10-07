import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import saveQuestionHandler from '../api/save-question';
import deleteQuestionHandler from '../api/delete-question';
import gradeHandler from '../api/grade';
import { setTokenVerifier, resetTokenVerifier } from '../lib/firebaseAdmin';

// Set emulator host env
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

async function runQuestionTests() {
  console.log('🚀 Memulai Test Suite Question Endpoints (/api/save-question, /api/delete-question, grade snapshot)...');

  let passed = 0;
  let failed = 0;

  async function test(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  [FAIL] ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  const teacherUid = 'guru_owner_question_test';
  const otherTeacherUid = 'guru_other_question_test';
  const studentUid = 'student_question_test';
  const testClassId = 'class_question_test_1';
  const archivedClassId = 'class_question_archived_test';
  const pretestId = 'pretest_question_test_1';

  // Setup data kelas, pretest, dan member
  await db.collection('classes').doc(testClassId).set({
    name: 'Kelas Fisika Soal',
    teacher_id: teacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('classes').doc(archivedClassId).set({
    name: 'Kelas Arsip Soal',
    teacher_id: teacherUid,
    status: 'Archived',
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('classes').doc(testClassId).collection('members').doc(studentUid).set({
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });

  await db.collection('pretests').doc(pretestId).set({
    title: 'Pretest Fisika Bab 1',
    class_id: testClassId,
    status: 'Published',
    duration: 30,
    max_attempts: 2,
    created_at: FieldValue.serverTimestamp(),
  });

  const archivedPretestId = 'pretest_archived_test_1';
  await db.collection('pretests').doc(archivedPretestId).set({
    title: 'Pretest Kelas Arsip',
    class_id: archivedClassId,
    status: 'Published',
    duration: 30,
    created_at: FieldValue.serverTimestamp(),
  });

  // 1. Tolak role USER
  await test('1. /api/save-question menolak pengguna dengan role USER (403 Forbidden)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'student@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-student-token' },
      body: {
        testId: pretestId,
        text: 'Berapakah 1 + 1?',
        options: ['1', '2', '3'],
        correct_option: 1,
      },
    };
    const res = createMockRes();
    await saveQuestionHandler(req, res as any);

    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 2. Tolak GURU yang bukan owner
  await test('2. /api/save-question menolak GURU non-owner (403 Forbidden)', async () => {
    setTokenVerifier(async () => ({
      uid: otherTeacherUid,
      email: 'other_guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-other-guru-token' },
      body: {
        testId: pretestId,
        text: 'Berapakah 1 + 1?',
        options: ['1', '2', '3'],
        correct_option: 1,
      },
    };
    const res = createMockRes();
    await saveQuestionHandler(req, res as any);

    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 3. Tolak jika kelas Archived
  await test('3. /api/save-question menolak perubahan soal di kelas Archived (400 Bad Request)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: archivedPretestId,
        text: 'Soal di kelas arsip',
        options: ['A', 'B'],
        correct_option: 0,
      },
    };
    const res = createMockRes();
    await saveQuestionHandler(req, res as any);

    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('Archived')) {
      throw new Error(`Expected archived error message, got: ${res.jsonData?.error}`);
    }
  });

  // 4. Tolak payload invalid (correct_option out of bounds, unknown fields)
  await test('4. /api/save-question menolak payload tidak valid dan field tak dikenal (400)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    // Sub-case A: Unknown field
    const reqA: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: pretestId,
        text: 'Soal A',
        options: ['A', 'B'],
        correct_option: 0,
        hackedField: 'malicious',
      },
    };
    const resA = createMockRes();
    await saveQuestionHandler(reqA, resA as any);
    if (resA.statusCode !== 400) throw new Error(`Expected 400 for unknown field, got ${resA.statusCode}`);

    // Sub-case B: correct_option out of bounds
    const reqB: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: pretestId,
        text: 'Soal B',
        options: ['A', 'B'],
        correct_option: 5,
      },
    };
    const resB = createMockRes();
    await saveQuestionHandler(reqB, resB as any);
    if (resB.statusCode !== 400) throw new Error(`Expected 400 for out-of-bounds correct_option, got ${resB.statusCode}`);
  });

  // 5. Guru Owner berhasil membuat soal baru & kunci jawaban secara atomik (version: 1)
  let createdQid = '';
  await test('5. /api/save-question berhasil membuat soal & kunci secara atomik tanpa bocor ke response', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: pretestId,
        text: 'Berapakah percepatan gravitasi bumi?',
        options: ['9.8 m/s^2', '100 m/s^2', '0 m/s^2'],
        correct_option: 0,
        points: 20,
        explanation: 'Nilai standar gravitasi di permukaan bumi sekitar 9.8 m/s^2.',
      },
    };
    const res = createMockRes();
    await saveQuestionHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (!res.jsonData?.success) throw new Error('Expected success: true');
    if (res.jsonData?.version !== 1) throw new Error(`Expected version 1, got ${res.jsonData?.version}`);
    // PASTIKAN: correct_option TIDAK bocor di respon API!
    if ('correct_option' in res.jsonData || 'explanation' in res.jsonData) {
      throw new Error('LEAK DETECTED: correct_option / explanation must NOT be present in API response');
    }

    createdQid = res.jsonData.qid;

    // Verifikasi di Firestore
    const qDoc = await db.collection('pretests').doc(pretestId).collection('questions').doc(createdQid).get();
    if (!qDoc.exists) throw new Error('Question document was not created');
    const qData = qDoc.data();
    if (qData?.text !== 'Berapakah percepatan gravitasi bumi?') throw new Error('Question text mismatch');
    if ('correct_option' in (qData || {})) throw new Error('LEAK: correct_option must not be stored in questions doc');

    const keyDoc = await db.collection('answer_keys').doc(pretestId).collection('items').doc(createdQid).get();
    if (!keyDoc.exists) throw new Error('Answer key document was not created');
    const keyData = keyDoc.data();
    if (keyData?.correct_option !== 0) throw new Error('Answer key correct_option mismatch');
    if (keyData?.points !== 20) throw new Error('Answer key points mismatch');
  });

  // 6. Guru Owner mengedit soal -> version naik jadi 2, atomik
  await test('6. /api/save-question menaikkan version menjadi 2 saat soal diedit', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: pretestId,
        qid: createdQid,
        text: 'Berapakah percepatan gravitasi standar bumi (revisi)?',
        options: ['9.8 m/s^2', '100 m/s^2', '0 m/s^2', '5 m/s^2'],
        correct_option: 0,
        points: 25,
      },
    };
    const res = createMockRes();
    await saveQuestionHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData?.version !== 2) throw new Error(`Expected version 2, got ${res.jsonData?.version}`);

    const qDoc = await db.collection('pretests').doc(pretestId).collection('questions').doc(createdQid).get();
    if (qDoc.data()?.version !== 2) throw new Error('Question version was not bumped in Firestore');
    if (qDoc.data()?.points !== 25) throw new Error('Question points not updated');

    const keyDoc = await db.collection('answer_keys').doc(pretestId).collection('items').doc(createdQid).get();
    if (keyDoc.data()?.version !== 2) throw new Error('Key version was not bumped');
    if (keyDoc.data()?.points !== 25) throw new Error('Key points not updated');
  });

  // 7. /api/grade menyimpan key_snapshot dan penilaian ke attempt
  const attemptId = 'attempt_question_test_1';
  await test('7. /api/grade menyimpan key_snapshot dan graded_at saat attempt dinilai', async () => {
    // Siapkan attempt in_progress
    await db.collection('attempts').doc(attemptId).set({
      user_id: studentUid,
      class_id: testClassId,
      test_id: pretestId,
      kind: 'pretest',
      status: 'in_progress',
      answers: {
        [createdQid]: 0, // Siswa menjawab benar
      },
      started_at: FieldValue.serverTimestamp(),
    });

    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'student@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-student-token' },
      body: { attemptId },
    };
    const res = createMockRes();
    await gradeHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (res.jsonData?.score !== 100) throw new Error(`Expected score 100, got ${res.jsonData?.score}`);

    // Periksa bahwa attempt di Firestore memiliki key_snapshot
    const attemptDoc = await db.collection('attempts').doc(attemptId).get();
    const data = attemptDoc.data();
    if (data?.status !== 'graded') throw new Error('Attempt status must be graded');
    if (!data?.key_snapshot || !data?.key_snapshot[createdQid]) {
      throw new Error('key_snapshot must be present in attempt document');
    }
    if (data.key_snapshot[createdQid].correct_option !== 0) {
      throw new Error('Snapshot correct_option mismatch');
    }
    if (data.key_snapshot[createdQid].points !== 25) {
      throw new Error('Snapshot points mismatch');
    }
  });

  // 8. Soft-delete question jika sudah ada attempt
  await test('8. /api/delete-question melakukan soft-delete jika kuis sudah memiliki attempt', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: pretestId,
        qid: createdQid,
      },
    };
    const res = createMockRes();
    await deleteQuestionHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData?.softDeleted !== true) throw new Error('Expected softDeleted: true');

    // Dokumen soal tetap ada tetapi bertanda deleted: true
    const qDoc = await db.collection('pretests').doc(pretestId).collection('questions').doc(createdQid).get();
    if (!qDoc.exists) throw new Error('Question doc should still exist on soft-delete');
    if (qDoc.data()?.deleted !== true) throw new Error('Question deleted field must be true');

    // Kunci jawaban tetap ada tetapi bertanda deleted: true
    const keyDoc = await db.collection('answer_keys').doc(pretestId).collection('items').doc(createdQid).get();
    if (!keyDoc.exists) throw new Error('Key doc should still exist on soft-delete');
    if (keyDoc.data()?.deleted !== true) throw new Error('Key deleted field must be true');
  });

  // 9. Hard-delete question jika BELUM ada attempt
  await test('9. /api/delete-question melakukan hard-delete jika kuis belum memiliki attempt', async () => {
    const unattemptedTestId = 'pretest_unattempted_1';
    await db.collection('pretests').doc(unattemptedTestId).set({
      title: 'Pretest Tanpa Attempt',
      class_id: testClassId,
      status: 'Published',
      created_at: FieldValue.serverTimestamp(),
    });

    // Buat 1 soal dulu
    const qidToHardDelete = 'q_hard_delete_test';
    await db.collection('pretests').doc(unattemptedTestId).collection('questions').doc(qidToHardDelete).set({
      text: 'Soal sementara',
      options: ['A', 'B'],
      points: 10,
    });
    await db.collection('answer_keys').doc(unattemptedTestId).collection('items').doc(qidToHardDelete).set({
      qid: qidToHardDelete,
      correct_option: 0,
      points: 10,
    });

    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: unattemptedTestId,
        qid: qidToHardDelete,
      },
    };
    const res = createMockRes();
    await deleteQuestionHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData?.softDeleted !== false) throw new Error('Expected softDeleted: false (hard delete)');

    // Dokumen harus benar-benar terhapus
    const qDoc = await db.collection('pretests').doc(unattemptedTestId).collection('questions').doc(qidToHardDelete).get();
    if (qDoc.exists) throw new Error('Question doc should be hard-deleted');

    const keyDoc = await db.collection('answer_keys').doc(unattemptedTestId).collection('items').doc(qidToHardDelete).get();
    if (keyDoc.exists) throw new Error('Key doc should be hard-deleted');
  });

  // 10. Tolak delete jika kelas Archived
  await test('10. /api/delete-question menolak penghapusan pada kelas Archived (400)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-guru-token' },
      body: {
        testId: archivedPretestId,
        qid: 'dummy_qid',
      },
    };
    const res = createMockRes();
    await deleteQuestionHandler(req, res as any);

    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
  });

  resetTokenVerifier();

  console.log(`\n========================================`);
  console.log(`QUESTION ENDPOINTS TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runQuestionTests().catch((err) => {
  console.error('Fatal question tests error:', err);
  process.exit(1);
});
