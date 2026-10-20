import aiHandler from '../api/ai';

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

async function runAiTests() {
  console.log('🚀 Memulai Test Suite AI Endpoint (/api/ai)...');

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
  await test('1. GET /api/ai mengembalikan 405 Method Not Allowed', async () => {
    const req: any = { method: 'GET', query: {}, headers: {} };
    const res = createMockRes();
    await aiHandler(req, res as any);
    if (res.statusCode !== 405) {
      throw new Error(`Expected status 405, got ${res.statusCode}`);
    }
  });

  // 2. Unauthenticated Request
  await test('2. POST /api/ai tanpa token ditolak dengan 401 Unauthorized', async () => {
    const req: any = {
      method: 'POST',
      query: {},
      headers: {},
      body: { action: 'tutor', prompt: 'Halo' },
    };
    const res = createMockRes();
    await aiHandler(req, res as any);
    if (res.statusCode !== 401) {
      throw new Error(`Expected status 401, got ${res.statusCode}`);
    }
  });

  console.log('\n========================================');
  console.log(`AI ENDPOINT TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log('========================================\n');

  if (failed > 0) {
    process.exit(1);
  }
}

runAiTests().catch((e) => {
  console.error('Fatal AI test error:', e);
  process.exit(1);
});
