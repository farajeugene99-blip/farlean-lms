import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import gradeHandler from '../api/grade';
import uploadSignHandler from '../api/upload-sign';
import createClassHandler from '../api/create-class';
import myClassesHandler from '../api/my-classes';
import classMembersHandler from '../api/class-members';
import classPurgeHandler from '../api/class-purge';
import { setTokenVerifier, resetTokenVerifier } from '../lib/firebaseAdmin';

// Set emulator host env
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
process.env.FIREBASE_PROJECT_ID = 'farlean-lms-test';
process.env.CLOUDINARY_API_SECRET = 'test_secret_12345';
process.env.CLOUDINARY_API_KEY = 'test_key_12345';
process.env.CLOUDINARY_CLOUD_NAME = 'farlean_test';

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
  const res: MockResponse = {
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
  return res;
}

async function runApiTests() {
  console.log('🚀 Memulai Backend API Test Suite (/api/grade & /api/upload-sign)...');

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

  const studentUid = 'mhs_grade_test_01';
  const guruUid = 'guru_upload_test_01';
  const testClassId = 'class_grade_01';
  const validTestId = 'pretest_grade_01';
  const draftTestId = 'pretest_draft_01';
  const expiredTestId = 'pretest_expired_01';

  // Seed Data untuk Penilaian
  await db.collection('classes').doc(testClassId).set({
    name: 'Kelas Uji',
    teacher_id: guruUid,
    status: 'Active',
  });
  await db.collection('classes').doc(testClassId).collection('members').doc(studentUid).set({
    display_name: 'Budi Test',
    status: 'active',
    account_type: 'MAHASISWA',
  });

  // Pretest Aktif
  await db.collection('pretests').doc(validTestId).set({
    class_id: testClassId,
    title: 'Pretest Algoritma',
    status: 'Published',
    duration: 30,
    deadline: new Date(Date.now() + 3600 * 1000), // 1 jam ke depan
  });

  // Kunci Jawaban Pretest Aktif
  await db.collection('answer_keys').doc(validTestId).collection('items').doc('q1').set({
    correct_option: 2,
    points: 50,
  });
  await db.collection('answer_keys').doc(validTestId).collection('items').doc('q2').set({
    correct_option: 0,
    points: 50,
  });

  // Pretest Draft
  await db.collection('pretests').doc(draftTestId).set({
    class_id: testClassId,
    title: 'Pretest Draft',
    status: 'Draft',
  });

  // Pretest Expired
  await db.collection('pretests').doc(expiredTestId).set({
    class_id: testClassId,
    title: 'Pretest Expired',
    status: 'Published',
    deadline: new Date(Date.now() - 3600 * 1000), // 1 jam lalu (terlewat)
  });

  // Skenario 1: Missing Token
  await test('1. /api/grade menolak request tanpa Authorization header (401)', async () => {
    const req = { method: 'POST', headers: {}, body: { attemptId: 'any' } } as any;
    const res = createMockRes();
    await gradeHandler(req, res as any);
    if (res.statusCode !== 401) throw new Error(`Expected 401, got ${res.statusCode}`);
  });

  // Skenario 2: Missing attemptId
  await test('2. /api/grade menolak request tanpa attemptId (400)', async () => {
    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = { method: 'POST', headers: { authorization: 'Bearer valid_token' }, body: {} } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);
      if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 3: Attempt tidak ditemukan
  await test('3. /api/grade mengembalikan 404 jika attempt tidak ditemukan', async () => {
    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { attemptId: 'non_existent_attempt' },
      } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);
      if (res.statusCode !== 404) throw new Error(`Expected 404, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 4: Kuis masih berstatus Draft
  await test('4. /api/grade menolak penilaian jika pretest masih berstatus Draft (400)', async () => {
    const draftAttemptRef = db.collection('attempts').doc('attempt_draft_test');
    await draftAttemptRef.set({
      user_id: studentUid,
      class_id: testClassId,
      test_id: draftTestId,
      status: 'in_progress',
      answers: {},
    });

    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { attemptId: 'attempt_draft_test' },
      } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);
      if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
      if (!res.jsonData?.error?.includes('Draft')) throw new Error('Error message must mention Draft');
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 5: Deadline terlewati
  await test('5. /api/grade menolak penilaian jika deadline kuis terlewat (400)', async () => {
    const expiredAttemptRef = db.collection('attempts').doc('attempt_expired_test');
    await expiredAttemptRef.set({
      user_id: studentUid,
      class_id: testClassId,
      test_id: expiredTestId,
      status: 'in_progress',
      answers: {},
    });

    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { attemptId: 'attempt_expired_test' },
      } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);
      if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
      if (!res.jsonData?.error?.includes('deadline')) throw new Error('Error message must mention deadline');
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 6: Penilaian Sukses & Perhitungan Skor Akurat
  const successfulAttemptId = 'attempt_valid_calc';
  await test('6. /api/grade menghitung skor dengan akurat dan mengunci attempt (status: graded)', async () => {
    await db.collection('attempts').doc(successfulAttemptId).set({
      user_id: studentUid,
      class_id: testClassId,
      test_id: validTestId,
      status: 'in_progress',
      answers: {
        q1: 2, // Benar (50 poin)
        q2: 1, // Salah (0 poin)
      },
      started_at: new Date(),
    });

    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { attemptId: successfulAttemptId },
      } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (res.jsonData?.score !== 50) throw new Error(`Expected score 50, got ${res.jsonData?.score}`);
      if (res.jsonData?.pointsEarned !== 50) throw new Error('Points earned must be 50');
      if (res.jsonData?.totalPoints !== 100) throw new Error('Total points must be 100');

      // Pastikan status di database berubah menjadi 'graded'
      const updatedDoc = await db.collection('attempts').doc(successfulAttemptId).get();
      if (updatedDoc.data()?.status !== 'graded') throw new Error('Attempt status in DB must be graded');

      // Pastikan TIDAK MEMBOCORKAN kunci jawaban ke client
      if (res.jsonData?.correct_option !== undefined || res.jsonData?.answer_keys !== undefined) {
        throw new Error('Security Breach: answer key was leaked in response!');
      }
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 7: Idempotensi Request Ganda
  await test('7. /api/grade idempoten saat dipanggil kedua kali (mengembalikan skor tanpa overwrite)', async () => {
    setTokenVerifier(async () => ({ uid: studentUid, email_verified: true, role: 'USER' }));
    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { attemptId: successfulAttemptId },
      } as any;
      const res = createMockRes();
      await gradeHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (res.jsonData?.idempotent !== true) throw new Error('Response must be flagged as idempotent');
      if (res.jsonData?.score !== 50) throw new Error('Score must remain 50');
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 8: /api/upload-sign Wewenang Role
  await test('8. /api/upload-sign menolak pengguna dengan role USER (403 Forbidden)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email_verified: true,
      role: 'USER',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: testClassId, folderType: 'manual_books' },
      } as any;
      const res = createMockRes();
      await uploadSignHandler(req, res as any);

      if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 9: /api/upload-sign Sukses untuk GURU
  await test('9. /api/upload-sign mengizinkan GURU dan menghasilkan signature Cloudinary aman (200)', async () => {
    setTokenVerifier(async () => ({
      uid: guruUid,
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: testClassId, folderType: 'manual_books' },
      } as any;
      const res = createMockRes();
      await uploadSignHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (!res.jsonData?.signature) throw new Error('Signature must be present in response');
      if (!res.jsonData?.timestamp) throw new Error('Timestamp must be present');
      if (res.jsonData?.folder !== `farlean/classes/${testClassId}/manual_books`) {
        throw new Error(`Folder mismatch: ${res.jsonData?.folder}`);
      }
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 10: /api/upload-sign Menolak GURU yang Bukan Pemilik Kelas
  await test('10. /api/upload-sign menolak GURU non-owner (403 Forbidden)', async () => {
    setTokenVerifier(async () => ({
      uid: 'guru_stranger_999',
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: testClassId, folderType: 'manual_books' },
      } as any;
      const res = createMockRes();
      await uploadSignHandler(req, res as any);

      if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 11: /api/create-class Proteksi Role USER
  await test('11. /api/create-class menolak pengguna dengan role USER (403 Forbidden)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email_verified: true,
      role: 'USER',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { name: 'Kelas Ilegal Mahasiswa' },
      } as any;
      const res = createMockRes();
      await createClassHandler(req, res as any);

      if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 12: /api/create-class Sukses untuk GURU
  let createdClassId = '';
  let createdClassCode = '';
  await test('12. /api/create-class membuat kelas baru, kode unik, dan membership owner (201 Created)', async () => {
    setTokenVerifier(async () => ({
      uid: guruUid,
      email: 'guru@dosen.farlean.edu',
      name: 'Dr. Guru Pengajar',
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: {
          name: 'Kelas Pemrograman Web Lanjut',
          description: 'Materi arsitektur web modern',
        },
      } as any;
      const res = createMockRes();
      await createClassHandler(req, res as any);

      if (res.statusCode !== 201) throw new Error(`Expected 201, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
      if (!res.jsonData?.classId) throw new Error('classId must be returned');
      if (!res.jsonData?.code) throw new Error('code must be returned');

      createdClassId = res.jsonData.classId;
      createdClassCode = res.jsonData.code;

      // Verifikasi di Firestore
      const classDoc = await db.collection('classes').doc(createdClassId).get();
      if (!classDoc.exists) throw new Error('Class document must exist in Firestore');
      if (classDoc.data()?.teacher_id !== guruUid) throw new Error('teacher_id mismatch');
      if (classDoc.data()?.status !== 'Active') throw new Error('status must be Active');

      const codeDoc = await db.collection('class_codes').doc(createdClassCode).get();
      if (!codeDoc.exists) throw new Error('class_codes mapping document must exist');
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 13: /api/create-class Menolak Kode Duplikat
  await test('13. /api/create-class menolak kode kelas duplikat (409 Conflict)', async () => {
    setTokenVerifier(async () => ({
      uid: guruUid,
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: {
          name: 'Kelas Duplikat',
          customCode: createdClassCode, // Kode yang sudah dipakai
        },
      } as any;
      const res = createMockRes();
      await createClassHandler(req, res as any);

      if (res.statusCode !== 409) throw new Error(`Expected 409, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 14: /api/my-classes Mengembalikan Owned & Joined
  await test('14. /api/my-classes mengembalikan daftar kelas yang dimiliki dan diikuti', async () => {
    setTokenVerifier(async () => ({
      uid: guruUid,
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'GET',
        headers: { authorization: 'Bearer valid_token' },
      } as any;
      const res = createMockRes();
      await myClassesHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (!Array.isArray(res.jsonData?.owned)) throw new Error('owned must be array');
      const hasCreated = res.jsonData.owned.some((c: any) => c.id === createdClassId);
      if (!hasCreated) throw new Error('owned must contain newly created class');
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 15: /api/class-members Membatasi Privasi Mahasiswa
  await test('15. /api/class-members hanya menampilkan display_name bagi mahasiswa biasa', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email_verified: true,
      role: 'USER',
    }));

    try {
      const req = {
        method: 'GET',
        headers: { authorization: 'Bearer valid_token' },
        query: { classId: testClassId },
      } as any;
      const res = createMockRes();
      await classMembersHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (res.jsonData?.isOwner !== false) throw new Error('isOwner must be false');
      const firstMember = res.jsonData?.members?.[0];
      if (firstMember && firstMember.account_type) {
        throw new Error('account_type must NOT be exposed to student');
      }
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 16: /api/class-members Menampilkan Detail untuk Dosen Owner
  await test('16. /api/class-members menampilkan status dan role untuk Dosen Owner', async () => {
    setTokenVerifier(async () => ({
      uid: guruUid,
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'GET',
        headers: { authorization: 'Bearer valid_token' },
        query: { classId: testClassId },
      } as any;
      const res = createMockRes();
      await classMembersHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
      if (res.jsonData?.isOwner !== true) throw new Error('isOwner must be true');
      const firstMember = res.jsonData?.members?.[0];
      if (!firstMember || !firstMember.account_type) {
        throw new Error('account_type must be visible to owner');
      }
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 17: /api/class-purge Proteksi Role & Validasi Anggota
  await test('17. /api/class-purge menolak non-admin (403) dan menolak kelas beranggota (400)', async () => {
    // Non-admin test
    setTokenVerifier(async () => ({
      uid: guruUid,
      email_verified: true,
      role: 'GURU',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: testClassId },
      } as any;
      const res = createMockRes();
      await classPurgeHandler(req, res as any);
      if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }

    // Admin test on class with members
    setTokenVerifier(async () => ({
      uid: 'admin_sys_01',
      email_verified: true,
      role: 'ADMIN',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: testClassId }, // testClassId has studentUid
      } as any;
      const res = createMockRes();
      await classPurgeHandler(req, res as any);
      if (res.statusCode !== 400) throw new Error(`Expected 400 for class with members, got ${res.statusCode}`);
    } finally {
      resetTokenVerifier();
    }
  });

  // Skenario 18: /api/class-purge Sukses Menghapus Kelas Kosong
  await test('18. /api/class-purge menghapus kelas kosong secara permanen untuk ADMIN (200 OK)', async () => {
    setTokenVerifier(async () => ({
      uid: 'admin_sys_01',
      email_verified: true,
      role: 'ADMIN',
    }));

    try {
      const req = {
        method: 'POST',
        headers: { authorization: 'Bearer valid_token' },
        body: { classId: createdClassId, force: true },
      } as any;
      const res = createMockRes();
      await classPurgeHandler(req, res as any);

      if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);

      const classDoc = await db.collection('classes').doc(createdClassId).get();
      if (classDoc.exists) throw new Error('Class must be deleted');
      const codeDoc = await db.collection('class_codes').doc(createdClassCode).get();
      if (codeDoc.exists) throw new Error('Class code mapping must be deleted');
    } finally {
      resetTokenVerifier();
    }
  });

  console.log(`\n========================================`);
  console.log(`BACKEND API TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runApiTests().catch((e) => {
  console.error('Fatal backend test error:', e);
  process.exit(1);
});
