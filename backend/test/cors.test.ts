import { applyCors, getAllowedOrigins, isOriginAllowed } from '../lib/cors';
import joinClassHandler from '../api/join-class';
import createClassHandler from '../api/create-class';

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

async function runCorsTests() {
  console.log('🚀 Memulai Test Suite CORS & Preflight (Phase 1 Commit A)...');

  let passed = 0;
  let failed = 0;

  function test(name: string, fn: () => void | Promise<void>) {
    try {
      fn();
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  [FAIL] ${name}`);
      console.error(`     Error: ${err.message}`);
      failed++;
    }
  }

  // 1. Uji daftar origin yang diizinkan (Dev Port Allowlist)
  test('1. Default dev origins memuat localhost:5000 dan 127.0.0.1:5000', () => {
    const origins = getAllowedOrigins();
    if (!origins.includes('http://localhost:5000')) throw new Error('localhost:5000 must be allowed');
    if (!origins.includes('http://127.0.0.1:5000')) throw new Error('127.0.0.1:5000 must be allowed');
    if (isOriginAllowed('http://evil-attacker.com')) throw new Error('evil domain must NOT be allowed');
  });

  // 2. Preflight OPTIONS request dengan origin terdaftar
  test('2. OPTIONS preflight dengan origin localhost:5000 mengembalikan 204 dan header CORS yang benar', () => {
    const req: any = {
      method: 'OPTIONS',
      headers: {
        origin: 'http://localhost:5000',
      },
    };
    const res = createMockRes();
    const handled = applyCors(req, res as any);

    if (!handled) throw new Error('applyCors must return true for OPTIONS');
    if (res.statusCode !== 204) throw new Error(`Expected status 204, got ${res.statusCode}`);
    if (!res.ended) throw new Error('res.end() must be called');
    if (res.headers['access-control-allow-origin'] !== 'http://localhost:5000') {
      throw new Error(`Expected allow-origin http://localhost:5000, got ${res.headers['access-control-allow-origin']}`);
    }
    if (res.headers['vary'] !== 'Origin') {
      throw new Error(`Expected Vary: Origin, got ${res.headers['vary']}`);
    }
    if (!res.headers['access-control-allow-headers']?.includes('Authorization')) {
      throw new Error('Access-Control-Allow-Headers must include Authorization');
    }
    if (!res.headers['access-control-allow-headers']?.includes('Content-Type')) {
      throw new Error('Access-Control-Allow-Headers must include Content-Type');
    }
    // Wajib: TIDAK mengirimkan Allow-Credentials
    if (res.headers['access-control-allow-credentials']) {
      throw new Error('Access-Control-Allow-Credentials must NOT be present (Bearer token used)');
    }
  });

  // 3. Preflight OPTIONS request dengan origin tidak terdaftar
  test('3. OPTIONS preflight dengan origin tidak terdaftar TIDAK mengirim header Allow-Origin (anti-wildcard)', () => {
    const req: any = {
      method: 'OPTIONS',
      headers: {
        origin: 'http://untrusted-site.xyz',
      },
    };
    const res = createMockRes();
    const handled = applyCors(req, res as any);

    if (!handled) throw new Error('applyCors must return true for OPTIONS');
    if (res.statusCode !== 204) throw new Error(`Expected status 204, got ${res.statusCode}`);
    if (res.headers['access-control-allow-origin']) {
      throw new Error('Access-Control-Allow-Origin must NOT be set for untrusted origin');
    }
  });

  // 4. Integrasi /api/join-class menangani OPTIONS tanpa membutuhkan Bearer Token
  test('4. /api/join-class menangani preflight OPTIONS tanpa error 401/405', async () => {
    const req: any = {
      method: 'OPTIONS',
      headers: {
        origin: 'http://127.0.0.1:5000',
      },
    };
    const res = createMockRes();
    await joinClassHandler(req, res as any);

    if (res.statusCode !== 204) throw new Error(`Expected 204, got ${res.statusCode}`);
    if (res.headers['access-control-allow-origin'] !== 'http://127.0.0.1:5000') {
      throw new Error('CORS origin header missing on /api/join-class');
    }
  });

  // 5. Integrasi /api/create-class menangani OPTIONS tanpa membutuhkan Bearer Token
  test('5. /api/create-class menangani preflight OPTIONS tanpa error 401/405', async () => {
    const req: any = {
      method: 'OPTIONS',
      headers: {
        origin: 'http://localhost:5000',
      },
    };
    const res = createMockRes();
    await createClassHandler(req, res as any);

    if (res.statusCode !== 204) throw new Error(`Expected 204, got ${res.statusCode}`);
    if (res.headers['access-control-allow-origin'] !== 'http://localhost:5000') {
      throw new Error('CORS origin header missing on /api/create-class');
    }
  });

  console.log(`\n========================================`);
  console.log(`CORS TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runCorsTests().catch((err) => {
  console.error('Fatal test error:', err);
  process.exit(1);
});
