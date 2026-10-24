import uploadSignHandler from '../api/upload-sign';
import { setTokenVerifier, resetTokenVerifier } from '../lib/firebaseAdmin';

interface MockResponse {
  statusCode: number;
  jsonData: any;
  headers: Record<string, string>;
  ended: boolean;
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
    ended: false,
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
      this.ended = true;
      return this;
    },
  };
}

async function runUploadSignTests() {
  console.log('🚀 Memulai Test Suite Upload Sign Endpoint (/api/upload-sign)...');

  let passed = 0;
  let failed = 0;

  async function test(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (e: any) {
      console.error(`  [FAIL] ${name}: ${e.message}`);
      failed++;
    }
  }

  // 1. Method Not Allowed
  await test('1. GET /api/upload-sign mengembalikan 405 Method Not Allowed', async () => {
    const req: any = { method: 'GET', query: {}, headers: {} };
    const res = createMockRes();
    await uploadSignHandler(req, res as any);
    if (res.statusCode !== 405) {
      throw new Error(`Expected status 405, got ${res.statusCode}`);
    }
  });

  // 2. Unauthenticated Request
  await test('2. POST /api/upload-sign tanpa token ditolak dengan 401 Unauthorized', async () => {
    const req: any = {
      method: 'POST',
      query: {},
      headers: {},
      body: { folderType: 'materials' },
    };
    const res = createMockRes();
    await uploadSignHandler(req, res as any);
    if (res.statusCode !== 401) {
      throw new Error(`Expected status 401, got ${res.statusCode}`);
    }
  });

  // 3. Mahasiswa (USER) mencoba upload ke 'materials' (hanya GURU/ADMIN) ditolak 403
  await test('3. POST /api/upload-sign folderType materials oleh mahasiswa (USER) ditolak 403 Forbidden', async () => {
    setTokenVerifier(async () => ({
      uid: 'student_test_1',
      email: 'student@kampus.ac.id',
      email_verified: true,
      role: 'USER',
    }));

    const req: any = {
      method: 'POST',
      query: {},
      headers: { authorization: 'Bearer dummy_token' },
      body: { folderType: 'materials', classId: 'class_test' },
    };
    const res = createMockRes();
    await uploadSignHandler(req, res as any);
    if (res.statusCode !== 403) {
      throw new Error(`Expected status 403, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    }
  });

  // 4. Mahasiswa upload assignments tanpa classId ditolak 400
  await test('4. POST /api/upload-sign folderType assignments tanpa classId ditolak 400 Bad Request', async () => {
    setTokenVerifier(async () => ({
      uid: 'student_test_1',
      email: 'student@kampus.ac.id',
      email_verified: true,
      role: 'USER',
    }));

    const req: any = {
      method: 'POST',
      query: {},
      headers: { authorization: 'Bearer dummy_token' },
      body: { folderType: 'assignments' },
    };
    const res = createMockRes();
    await uploadSignHandler(req, res as any);
    if (res.statusCode !== 400) {
      throw new Error(`Expected status 400, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    }
  });

  // 5. Mahasiswa upload assignments tanpa assignmentId ditolak 400
  await test('5. POST /api/upload-sign folderType assignments tanpa assignmentId ditolak 400 Bad Request', async () => {
    setTokenVerifier(async () => ({
      uid: 'student_test_1',
      email: 'student@kampus.ac.id',
      email_verified: true,
      role: 'USER',
    }));

    const req: any = {
      method: 'POST',
      query: {},
      headers: { authorization: 'Bearer dummy_token' },
      body: { folderType: 'assignments', classId: 'class_test_1' },
    };
    const res = createMockRes();
    await uploadSignHandler(req, res as any);
    if (res.statusCode !== 400) {
      throw new Error(`Expected status 400, got ${res.statusCode}: ${JSON.stringify(res.jsonData)}`);
    }
    resetTokenVerifier();
  });

  console.log('\n========================================');
  console.log(`UPLOAD SIGN TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log('========================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runUploadSignTests().catch((e) => {
  console.error('Fatal Upload Sign test error:', e);
  process.exit(1);
});
