import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import publishMeetingsHandler from '../api/publish-meetings';
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

async function runPublishMeetingsTests() {
  console.log('🚀 Memulai Test Suite /api/publish-meetings (C3 Scheduled Publish)...');

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

  const teacherUid = 'guru_sched_owner_' + Date.now();
  const otherTeacherUid = 'guru_sched_other_' + Date.now();
  const studentUid = 'student_sched_' + Date.now();
  const testClassId = 'class_sched_test_' + Date.now();
  const otherClassId = 'class_sched_other_' + Date.now();

  const pastDate = new Date(Date.now() - 60 * 60 * 1000);
  const futureDate = new Date(Date.now() + 24 * 60 * 60 * 1000);

  // Setup classes
  await db.collection('classes').doc(testClassId).set({
    name: 'Kelas Jadwal Publikasi',
    teacher_id: teacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });
  await db.collection('classes').doc(testClassId).collection('members').doc(studentUid).set({
    display_name: 'Siswa Penjadwalan',
    account_type: 'MAHASISWA',
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });
  await db.collection('classes').doc(otherClassId).set({
    name: 'Kelas Lain',
    teacher_id: otherTeacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });

  // Setup meetings: 1 jatuh tempo, 1 masa depan, 1 kelas lain yang jatuh tempo
  const dueMeetingId = 'meet_sched_due_' + Date.now();
  const futureMeetingId = 'meet_sched_future_' + Date.now();
  const otherClassMeetingId = 'meet_sched_otherclass_' + Date.now();

  await db.collection('meetings').doc(dueMeetingId).set({
    class_id: testClassId,
    number: 5,
    title: 'Pertemuan Jatuh Tempo',
    status: 'Scheduled',
    publish_at: pastDate,
  });
  await db.collection('meetings').doc(futureMeetingId).set({
    class_id: testClassId,
    number: 6,
    title: 'Pertemuan Masa Depan',
    status: 'Scheduled',
    publish_at: futureDate,
  });
  await db.collection('meetings').doc(otherClassMeetingId).set({
    class_id: otherClassId,
    number: 1,
    title: 'Pertemuan Kelas Lain Jatuh Tempo',
    status: 'Scheduled',
    publish_at: pastDate,
  });

  const asGuruOwner = () =>
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@dosen.farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

  // 1. Menolak role USER
  await test('1. Menolak pengguna dengan role USER (403)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'siswa@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = { method: 'POST', headers: { authorization: 'Bearer mock-token' }, body: {} };
    const res = createMockRes();
    await publishMeetingsHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 2. GURU non-owner pada sweep global melewati pertemuan kelas lain (skippedForbidden)
  await test('2. GURU non-owner hanya mempromosikan kelasnya sendiri (kelas lain dilewati)', async () => {
    asGuruOwner();
    const req: any = { method: 'POST', headers: { authorization: 'Bearer mock-token' }, body: {} };
    const res = createMockRes();
    await publishMeetingsHandler(req, res as any);
    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (res.jsonData.promotedCount !== 1) {
      throw new Error(`Expected promotedCount 1, got ${res.jsonData.promotedCount}`);
    }
    if (!res.jsonData.promoted.includes(dueMeetingId)) {
      throw new Error(`Expected ${dueMeetingId} promoted, got ${JSON.stringify(res.jsonData.promoted)}`);
    }
    if (res.jsonData.skippedFuture !== 1) {
      throw new Error(`Expected skippedFuture 1, got ${res.jsonData.skippedFuture}`);
    }
    if ((res.jsonData.skippedForbidden ?? 0) < 1) {
      throw new Error(`Expected skippedForbidden >= 1, got ${res.jsonData.skippedForbidden}`);
    }
  });

  // 3. Verifikasi dokumen: jatuh tempo -> Published + publish_at dibersihkan
  await test('3. Dokumen jatuh tempo menjadi Published dan publish_at dihapus', async () => {
    const doc = await db.collection('meetings').doc(dueMeetingId).get();
    const data = doc.data() || {};
    if (data.status !== 'Published') throw new Error(`Expected Published, got ${data.status}`);
    if (data.publish_at !== null && data.publish_at !== undefined) {
      throw new Error(`Expected publish_at cleared, got ${JSON.stringify(data.publish_at)}`);
    }
  });

  // 4. Pertemuan masa depan tetap Scheduled
  await test('4. Pertemuan masa depan tetap Scheduled (tidak dipromosikan dini)', async () => {
    const doc = await db.collection('meetings').doc(futureMeetingId).get();
    if ((doc.data() || {}).status !== 'Scheduled') {
      throw new Error(`Expected Scheduled, got ${(doc.data() || {}).status}`);
    }
  });

  // 5. Idempoten: pemanggilan kedua tidak mempromosikan apa pun
  await test('5. Idempoten: run kedua menghasilkan promotedCount 0', async () => {
    asGuruOwner();
    const req: any = { method: 'POST', headers: { authorization: 'Bearer mock-token' }, body: { classId: testClassId } };
    const res = createMockRes();
    await publishMeetingsHandler(req, res as any);
    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}`);
    if (res.jsonData.promotedCount !== 0) {
      throw new Error(`Expected promotedCount 0, got ${res.jsonData.promotedCount}`);
    }
  });

  // 6. Cron secret mempromosikan lintas kelas (termasuk kelas lain)
  await test('6. Mode cron (x-cron-secret) mempromosikan jatuh tempo lintas kelas', async () => {
    process.env.MEETING_PUBLISH_CRON_SECRET = 'test-cron-secret-123';
    const req: any = {
      method: 'POST',
      headers: { 'x-cron-secret': 'test-cron-secret-123' },
      body: {},
    };
    const res = createMockRes();
    await publishMeetingsHandler(req, res as any);
    delete process.env.MEETING_PUBLISH_CRON_SECRET;
    if (res.statusCode !== 200) throw new Error(`Expected 200, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (!res.jsonData.promoted.includes(otherClassMeetingId)) {
      throw new Error(`Expected ${otherClassMeetingId} promoted via cron, got ${JSON.stringify(res.jsonData.promoted)}`);
    }
  });

  resetTokenVerifier();

  console.log(`\n========================================`);
  console.log(`PUBLISH-MEETINGS TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runPublishMeetingsTests().catch((e) => {
  console.error('Fatal publish-meetings test error:', e);
  process.exit(1);
});
