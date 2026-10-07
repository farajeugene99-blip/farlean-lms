import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import joinClassHandler from '../api/join-class';
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

async function runJoinClassTests() {
  console.log('🚀 Memulai Test Suite /api/join-class Matrix...');

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

  const activeClassId = 'class_join_test_active';
  const archivedClassId = 'class_join_test_archived';
  const activeCode = 'JOINTEST1';
  const archivedCode = 'JOINARCH1';

  // Seed data
  await db.collection('classes').doc(activeClassId).set({
    name: 'Kelas Join Aktif',
    code: activeCode,
    teacher_id: 'guru_join_owner',
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('classes').doc(archivedClassId).set({
    name: 'Kelas Join Arsip',
    code: archivedCode,
    teacher_id: 'guru_join_owner',
    status: 'Archived',
    created_at: FieldValue.serverTimestamp(),
  });

  // Seed anggota removed di activeClassId
  const removedUserUid = 'mhs_removed_join_test';
  await db.collection('classes').doc(activeClassId).collection('members').doc(removedUserUid).set({
    status: 'removed',
    display_name: 'Mahasiswa Dikeluarkan',
    joined_at: FieldValue.serverTimestamp(),
  });

  // Seed anggota already active
  const alreadyActiveUid = 'mhs_already_active_test';
  await db.collection('classes').doc(activeClassId).collection('members').doc(alreadyActiveUid).set({
    status: 'active',
    display_name: 'Mahasiswa Sudah Aktif',
    joined_at: FieldValue.serverTimestamp(),
  });

  // 1. Menolak request tanpa Authorization header
  await test('1. Menolak request tanpa Authorization header (401)', async () => {
    const req: any = { method: 'POST', headers: {}, body: { classCode: activeCode } };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 401) throw new Error(`Expected 401, got ${res.statusCode}`);
  });

  // 2. Menolak token unverified
  await test('2. Menolak pengguna dengan email belum diverifikasi (403)', async () => {
    setTokenVerifier(async () => ({
      uid: 'user_unverified_join',
      email: 'unverified@farlean.edu',
      email_verified: false,
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: activeCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 3. Menolak kode kelas kosong atau format invalid
  await test('3. Menolak kode kelas kosong atau karakter tidak valid (400)', async () => {
    setTokenVerifier(async () => ({
      uid: 'user_valid_join_1',
      email: 'mhs@farlean.edu',
      email_verified: true,
    } as any));

    // Kode kosong
    const req1: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: '' },
    };
    const res1 = createMockRes();
    await joinClassHandler(req1, res1 as any);
    if (res1.statusCode !== 400) throw new Error(`Expected 400 for empty code, got ${res1.statusCode}`);

    // Kode terlalu pendek
    const req2: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: 'ABC' },
    };
    const res2 = createMockRes();
    await joinClassHandler(req2, res2 as any);
    if (res2.statusCode !== 400) throw new Error(`Expected 400 for short code, got ${res2.statusCode}`);
  });

  // 4. Mengembalikan 404 jika kode kelas tidak ditemukan
  await test('4. Mengembalikan 404 jika kode kelas tidak ada di database', async () => {
    setTokenVerifier(async () => ({
      uid: 'user_valid_join_2',
      email: 'mhs@farlean.edu',
      email_verified: true,
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: 'NOTFOUND99' },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 404) throw new Error(`Expected 404, got ${res.statusCode}`);
  });

  // 5. Menolak kelas Archived
  await test('5. Menolak jika kelas tujuan berstatus Archived (400)', async () => {
    setTokenVerifier(async () => ({
      uid: 'user_valid_join_3',
      email: 'mhs@farlean.edu',
      email_verified: true,
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: archivedCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('diarsipkan')) {
      throw new Error(`Expected message about archived class, got ${res.jsonData?.error}`);
    }
  });

  // 6. Menolak jika pengguna sudah menjadi anggota aktif
  await test('6. Menolak jika pengguna sudah terdaftar sebagai anggota aktif (400)', async () => {
    setTokenVerifier(async () => ({
      uid: alreadyActiveUid,
      email: 'active@farlean.edu',
      email_verified: true,
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: activeCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('sudah menjadi anggota')) {
      throw new Error(`Expected message about already member, got ${res.jsonData?.error}`);
    }
  });

  // 7. Menolak jika anggota berstatus removed
  await test('7. Menolak anggota yang telah dikeluarkan/removed oleh pengajar (403)', async () => {
    setTokenVerifier(async () => ({
      uid: removedUserUid,
      email: 'removed@farlean.edu',
      email_verified: true,
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: activeCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('dikeluarkan')) {
      throw new Error(`Expected message about removed user, got ${res.jsonData?.error}`);
    }
  });

  // 8. Mahasiswa Farlean (domain farlean.edu) langsung berstatus active
  const newStudentUid = `mhs_baru_farlean_${Date.now()}`;
  await test('8. Mahasiswa domain farlean.edu otomatis menjadi anggota aktif (status: active)', async () => {
    setTokenVerifier(async () => ({
      uid: newStudentUid,
      email: 'budi@students.farlean.edu',
      email_verified: true,
      name: 'Budi Santoso',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: activeCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (res.jsonData?.status !== 'active') throw new Error(`Expected status active, got ${res.jsonData?.status}`);
    if (res.jsonData?.classId !== activeClassId) throw new Error(`Expected classId ${activeClassId}, got ${res.jsonData?.classId}`);

    // Verifikasi di Firestore
    const memberDoc = await db.collection('classes').doc(activeClassId).collection('members').doc(newStudentUid).get();
    if (!memberDoc.exists || memberDoc.data()?.status !== 'active') {
      throw new Error('Membership was not set to active in Firestore');
    }
  });

  // 9. Akun umum (email gmail/yahoo) berstatus pending
  const generalUserUid = `umum_user_join_${Date.now()}`;
  await test('9. Pengguna umum (bukan domain universitas) berstatus pending', async () => {
    setTokenVerifier(async () => ({
      uid: generalUserUid,
      email: 'umum@gmail.com',
      email_verified: true,
      name: 'Umum User',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: activeCode },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);

    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData?.status !== 'pending') throw new Error(`Expected status pending, got ${res.jsonData?.status}`);

    // Uji idempotensi: request ulang dengan akun pending yang sama
    const res2 = createMockRes();
    await joinClassHandler(req, res2 as any);
    if (res2.statusCode !== 200 || res2.jsonData?.status !== 'pending') {
      throw new Error('Idempotent pending check failed');
    }
  });

  // 10. Rate limiting (maksimal 5 kesalahan)
  await test('10. Rate limit: mengembalikan 429 setelah 5 kali gagal', async () => {
    const rateLimitUid = `spammer_user_${Date.now()}`;
    setTokenVerifier(async () => ({
      uid: rateLimitUid,
      email: 'spammer@farlean.edu',
      email_verified: true,
    } as any));

    // Siapkan rate limit document dengan 5 failed attempts
    await db.collection('rate_limits').doc(rateLimitUid).set({
      failed_attempts: 5,
      window_start: Date.now(),
      last_attempt: FieldValue.serverTimestamp(),
    });

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classCode: 'NOTFOUND12' },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);

    if (res.statusCode !== 429) throw new Error(`Expected 429 Too Many Requests, got ${res.statusCode}`);
  });

  resetTokenVerifier();

  console.log(`\n========================================`);
  console.log(`JOIN-CLASS TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runJoinClassTests().catch((e) => {
  console.error('Fatal join-class test error:', e);
  process.exit(1);
});
