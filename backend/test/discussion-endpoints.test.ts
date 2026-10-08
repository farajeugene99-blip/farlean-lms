import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import discussionThreadHandler from '../api/discussion-thread';
import discussionReplyHandler from '../api/discussion-reply';
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

async function runDiscussionTests() {
  console.log('🚀 Memulai Test Suite Discussion Endpoints & Rules (/api/discussion-thread, /api/discussion-reply)...');

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

  const teacherUid = 'guru_disc_owner_' + Date.now();
  const studentUid = 'mhs_disc_member_' + Date.now();
  const outsiderUid = 'mhs_disc_outsider_' + Date.now();
  const classId = 'class_disc_test_' + Date.now();
  const archivedClassId = 'class_disc_archived_' + Date.now();

  // Seed Data Kelas & Member
  await db.collection('classes').doc(classId).set({
    name: 'Kelas Diskusi Komputasi',
    teacher_id: teacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('classes').doc(archivedClassId).set({
    name: 'Kelas Diskusi Arsip',
    teacher_id: teacherUid,
    status: 'Archived',
    created_at: FieldValue.serverTimestamp(),
  });

  await db.collection('classes').doc(classId).collection('members').doc(studentUid).set({
    display_name: 'Ahmad Mahasiswa',
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });

  await db.collection('users').doc(teacherUid).set({
    name: 'Prof. Guru Pengajar',
    role: 'GURU',
    account_type: 'DOSEN',
  });

  // 1. Menolak request tanpa Authorization (401)
  await test('1. /api/discussion-thread menolak request tanpa token (401)', async () => {
    const req: any = { method: 'POST', headers: {}, body: { classId, title: 'Judul', body: 'Isi' } };
    const res = createMockRes();
    await discussionThreadHandler(req, res as any);
    if (res.statusCode !== 401) throw new Error(`Expected 401, got ${res.statusCode}`);
  });

  // 2. Menolak non-member membuat thread (403)
  await test('2. /api/discussion-thread menolak bukan anggota kelas (403)', async () => {
    setTokenVerifier(async () => ({
      uid: outsiderUid,
      email: 'outsider@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classId, title: 'Diskusi Ilegal', body: 'Saya bukan anggota' },
    };
    const res = createMockRes();
    await discussionThreadHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 3. Menolak thread di kelas Archived (400)
  await test('3. /api/discussion-thread menolak pembuatan diskusi di kelas Archived (400)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@dosen.farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: { classId: archivedClassId, title: 'Diskusi Baru', body: 'Halo semuanya' },
    };
    const res = createMockRes();
    await discussionThreadHandler(req, res as any);
    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
  });

  // 4. Anggota aktif berhasil membuat thread dengan display_name terpercaya dari DB (201)
  let createdDiscussionId = '';
  await test('4. Anggota aktif berhasil membuat thread dan display_name aman dari impersonasi (201)', async () => {
    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'ahmad@students.farlean.edu',
      email_verified: true,
      name: 'Nama Palsu Yang Ingin Dipalsukan',
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: {
        classId,
        title: 'Tanya Mengenai Algoritma Greedy',
        body: 'Apakah algoritma greedy selalu menghasilkan solusi optimal untuk knapsack problem?',
      },
    };
    const res = createMockRes();
    await discussionThreadHandler(req, res as any);

    if (res.statusCode !== 201) throw new Error(`Expected 201, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    if (!res.jsonData?.discussionId) throw new Error('Missing discussionId in response');
    createdDiscussionId = res.jsonData.discussionId;

    // Verifikasi di Firestore
    const doc = await db.collection('discussions').doc(createdDiscussionId).get();
    if (!doc.exists) throw new Error('Discussion doc not created');
    const data = doc.data()!;
    if (data.author_id !== studentUid) throw new Error('Author ID mismatch');
    // PASTIKAN: author_display_name diambil dari data membership 'Ahmad Mahasiswa', bukan dari token palsu!
    if (data.author_display_name !== 'Ahmad Mahasiswa') {
      throw new Error(`Impersonation detected! Expected 'Ahmad Mahasiswa', got '${data.author_display_name}'`);
    }
    if (data.status !== 'ACTIVE') throw new Error('Expected status ACTIVE');
    if (data.reply_count !== 0) throw new Error('Expected reply_count 0');
  });

  // 5. Guru pemilik berhasil membuat thread (201)
  await test('5. Guru pemilik kelas berhasil membuat thread pengumuman diskusi (201)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@dosen.farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: {
        classId,
        title: 'Pengumuman Sesi Tanya Jawab Bab 3',
        body: 'Silakan gunakan thread ini untuk bertanya seputar materi kalkulus lanjut.',
      },
    };
    const res = createMockRes();
    await discussionThreadHandler(req, res as any);

    if (res.statusCode !== 201) throw new Error(`Expected 201, got ${res.statusCode}`);
    const doc = await db.collection('discussions').doc(res.jsonData.discussionId).get();
    if (doc.data()?.author_display_name !== 'Prof. Guru Pengajar') {
      throw new Error(`Expected teacher name, got ${doc.data()?.author_display_name}`);
    }
  });

  // 6. Menolak balasan dari non-member (403)
  await test('6. /api/discussion-reply menolak balasan dari pengguna luar kelas (403)', async () => {
    setTokenVerifier(async () => ({
      uid: outsiderUid,
      email: 'outsider@farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: {
        discussionId: createdDiscussionId,
        body: 'Balasan penyusup',
      },
    };
    const res = createMockRes();
    await discussionReplyHandler(req, res as any);
    if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
  });

  // 7. Pengajar & Siswa berhasil membalas dan reply_count ter-increment secara atomik (201)
  let createdReplyId = '';
  await test('7. /api/discussion-reply menulis balasan dan meng-increment reply_count & last_activity_at (201)', async () => {
    setTokenVerifier(async () => ({
      uid: teacherUid,
      email: 'guru@dosen.farlean.edu',
      email_verified: true,
      role: 'GURU',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: {
        discussionId: createdDiscussionId,
        body: 'Untuk fractional knapsack greedy optimal, tetapi untuk 0/1 knapsack harus menggunakan dynamic programming.',
      },
    };
    const res = createMockRes();
    await discussionReplyHandler(req, res as any);

    if (res.statusCode !== 201) throw new Error(`Expected 201, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    createdReplyId = res.jsonData.replyId;

    // Verifikasi reply document
    const replyDoc = await db.collection('discussions').doc(createdDiscussionId).collection('replies').doc(createdReplyId).get();
    if (!replyDoc.exists) throw new Error('Reply document not found');
    if (replyDoc.data()?.author_id !== teacherUid) throw new Error('Reply author mismatch');

    // Verifikasi parent discussion increment
    const parentDoc = await db.collection('discussions').doc(createdDiscussionId).get();
    if (parentDoc.data()?.reply_count !== 1) {
      throw new Error(`Expected reply_count 1, got ${parentDoc.data()?.reply_count}`);
    }
  });

  // 8. Menolak balasan pada thread ARCHIVED (400)
  await test('8. /api/discussion-reply menolak balasan pada thread berstatus ARCHIVED (400)', async () => {
    // Arsipkan thread
    await db.collection('discussions').doc(createdDiscussionId).update({ status: 'ARCHIVED' });

    setTokenVerifier(async () => ({
      uid: studentUid,
      email: 'ahmad@students.farlean.edu',
      email_verified: true,
      role: 'USER',
    } as any));

    const req: any = {
      method: 'POST',
      headers: { authorization: 'Bearer mock-token' },
      body: {
        discussionId: createdDiscussionId,
        body: 'Terima kasih penjelasannya Prof.',
      },
    };
    const res = createMockRes();
    await discussionReplyHandler(req, res as any);

    if (res.statusCode !== 400) throw new Error(`Expected 400, got ${res.statusCode}`);
    if (!res.jsonData?.error?.includes('diarsipkan')) {
      throw new Error(`Expected error about archived discussion, got: ${res.jsonData?.error}`);
    }
  });

  resetTokenVerifier();

  console.log(`\n========================================`);
  console.log(`DISCUSSION TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runDiscussionTests().catch((e) => {
  console.error('Fatal discussion test error:', e);
  process.exit(1);
});
