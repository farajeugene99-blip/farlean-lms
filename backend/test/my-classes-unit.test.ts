import myClassesHandler from '../api/_handlers/my-classes';
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

async function runMyClassesUnitTests() {
  console.log('🚀 Memulai Unit Test /api/my-classes Endpoint...');

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
  await test('1. POST /api/my-classes mengembalikan 405 Method Not Allowed', async () => {
    const req: any = { method: 'POST', query: {}, headers: {} };
    const res = createMockRes();
    await myClassesHandler(req, res as any);
    if (res.statusCode !== 405) throw new Error(`Expected 405, got ${res.statusCode}`);
  });

  // 2. Unauthorized tanpa token
  await test('2. GET /api/my-classes tanpa token ditolak dengan 401 Unauthorized', async () => {
    const req: any = { method: 'GET', query: {}, headers: {} };
    const res = createMockRes();
    await myClassesHandler(req, res as any);
    if (res.statusCode !== 401) throw new Error(`Expected 401, got ${res.statusCode}`);
  });

  // 3. Ditolak jika email belum diverifikasi
  await test('3. GET /api/my-classes dengan email belum diverifikasi ditolak 403 Forbidden', async () => {
    setTokenVerifier(async () => ({
      uid: 'unverified_uid_1',
      email: 'user@farlean.edu',
      email_verified: false,
      role: 'USER',
    } as any));

    try {
      const req: any = {
        method: 'GET',
        query: {},
        headers: { authorization: 'Bearer mock_token' },
      };
      const res = createMockRes();
      await myClassesHandler(req, res as any);
      if (res.statusCode !== 403) throw new Error(`Expected 403, got ${res.statusCode}`);
      if (!res.jsonData?.error?.toLowerCase().includes('verifikasi')) {
        throw new Error(`Expected error message about verification, got ${res.jsonData?.error}`);
      }
    } finally {
      resetTokenVerifier();
    }
  });

  console.log(`\n========================================`);
  console.log(`MY-CLASSES UNIT TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) process.exit(1);
}

runMyClassesUnitTests().catch((e) => {
  console.error('Fatal test error:', e);
  process.exit(1);
});
