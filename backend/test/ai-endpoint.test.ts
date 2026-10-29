import aiHandler, {
  extractDeltaPlainText,
  getAiQuotaConfig,
  AI_QUOTA_CONFIG,
  PRIMARY_MODEL,
  FALLBACK_MODELS,
  getFallbackModels,
  generateWithFallback,
  ensureClosedCodeBlocks,
  HUTAO_AI_SYSTEM_INSTRUCTION,
} from '../api/ai';

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

  // 3. Delta Extractor Tests
  await test('3. extractDeltaPlainText mengekstrak Delta JSON ops array dengan tepat', async () => {
    const deltaOps = [
      { insert: 'Bab 1: Pengenalan Lean Manufacturing\n' },
      { insert: 'Lean manufacturing bertujuan mengurangi waste.\n' },
    ];
    const text = extractDeltaPlainText(deltaOps);
    if (!text.includes('Pengenalan Lean Manufacturing') || !text.includes('mengurangi waste')) {
      throw new Error(`Ekstraksi gagal: ${text}`);
    }
  });

  await test('4. extractDeltaPlainText mengekstrak JSON string Delta ops dengan aman', async () => {
    const rawJson = JSON.stringify([
      { insert: 'Definisi Kaizen: perbaikan terus-menerus.' },
    ]);
    const text = extractDeltaPlainText(rawJson);
    if (text !== 'Definisi Kaizen: perbaikan terus-menerus.') {
      throw new Error(`Ekstraksi JSON string gagal: ${text}`);
    }
  });

  await test('5. extractDeltaPlainText menangani string biasa atau null secara graceful', async () => {
    const plain = 'Teks murni tanpa format Delta';
    if (extractDeltaPlainText(plain) !== plain) {
      throw new Error('Gagal mempertahankan teks murni');
    }
    if (extractDeltaPlainText(null) !== '') {
      throw new Error('Null tidak menghasilkan string kosong');
    }
  });

  // 6. Quota Config Dual-Tier
  await test('6. AI_QUOTA_CONFIG mengonfigurasi batas burst (15 menit) dan daily (24 jam) per role', async () => {
    // USER
    const userTutor = getAiQuotaConfig('USER', 'tutor');
    if (userTutor.burstMax !== 10 || userTutor.dailyMax !== 30) {
      throw new Error(`USER tutor invalid: ${JSON.stringify(userTutor)}`);
    }

    // GURU
    const guruTutor = getAiQuotaConfig('GURU', 'tutor');
    if (guruTutor.burstMax !== 20 || guruTutor.dailyMax !== 100) {
      throw new Error(`GURU tutor invalid: ${JSON.stringify(guruTutor)}`);
    }
    const guruVideo = getAiQuotaConfig('GURU', 'video-description');
    if (guruVideo.burstMax !== 5 || guruVideo.dailyMax !== 25) {
      throw new Error(`GURU video invalid: ${JSON.stringify(guruVideo)}`);
    }

    // ADMIN
    const adminTutor = getAiQuotaConfig('ADMIN', 'tutor');
    if (adminTutor.burstMax !== 30 || adminTutor.dailyMax !== 200) {
      throw new Error(`ADMIN tutor invalid: ${JSON.stringify(adminTutor)}`);
    }
  });

  // 7. Fallback Quota Config untuk role tak dikenal
  await test('7. getAiQuotaConfig fallback ke USER config untuk role tak dikenal', async () => {
    const unknownConfig = getAiQuotaConfig('STRANGER', 'tutor');
    if (unknownConfig.burstMax !== 10 || unknownConfig.dailyMax !== 30) {
      throw new Error(`Fallback unknown role failed: ${JSON.stringify(unknownConfig)}`);
    }
  });

  // 8. Fallback Models Configuration
  await test('8. getFallbackModels menyediakan daftar model dengan PRIMARY_MODEL di awal tanpa duplikasi', async () => {
    const models = getFallbackModels();
    if (!models || models.length === 0) {
      throw new Error('Daftar fallback model kosong');
    }
    if (models[0] !== PRIMARY_MODEL) {
      throw new Error(`Model pertama bukan PRIMARY_MODEL: ${models[0]} vs ${PRIMARY_MODEL}`);
    }
    const unique = new Set(models);
    if (unique.size !== models.length) {
      throw new Error(`Daftar model memiliki duplikat: ${JSON.stringify(models)}`);
    }
  });

  // 9. generateWithFallback - Success on first try
  await test('9. generateWithFallback berhasil mengembalikan output jika model pertama sukses', async () => {
    let attemptedModel = '';
    const mockAi = {
      models: {
        generateContent: async (cfg: any) => {
          attemptedModel = cfg.model;
          return { text: `Success from ${cfg.model}` };
        },
      },
    };

    const res: any = await generateWithFallback(mockAi, { contents: 'Halo' });
    if (!res || !res.text || !res.text.includes('Success from')) {
      throw new Error(`Hasil tidak sesuai: ${JSON.stringify(res)}`);
    }
    if (attemptedModel !== PRIMARY_MODEL) {
      throw new Error(`Model yang dipanggil bukan PRIMARY_MODEL: ${attemptedModel}`);
    }
  });

  // 10. generateWithFallback - Fallback on 404 / NOT_FOUND / no longer available
  await test('10. generateWithFallback otomatis mencoba model berikutnya saat model pertama 404 / no longer available', async () => {
    const attemptedModels: string[] = [];
    const mockAi = {
      models: {
        generateContent: async (cfg: any) => {
          attemptedModels.push(cfg.model);
          if (attemptedModels.length === 1) {
            const err: any = new Error(
              'This model models/gemini-2.5-flash is no longer available to new users. Please update your code...'
            );
            err.status = 404;
            throw err;
          }
          return { text: `Success from fallback ${cfg.model}` };
        },
      },
    };

    const res: any = await generateWithFallback(mockAi, { contents: 'Halo' });
    if (attemptedModels.length < 2) {
      throw new Error(`Harusnya mencoba minimal 2 model, hanya mencoba: ${attemptedModels.length}`);
    }
    if (!res.text.includes('Success from fallback')) {
      throw new Error(`Output tidak valid: ${res.text}`);
    }
  });

  // 11. generateWithFallback - Throw non-404 errors immediately (e.g. 429 Quota Exceeded)
  await test('11. generateWithFallback langsung melempar error non-404 (misal 429 kuota) tanpa retry ke model lain', async () => {
    let calls = 0;
    const mockAi = {
      models: {
        generateContent: async () => {
          calls++;
          const err: any = new Error('Resource has been exhausted (quota exceeded)');
          err.status = 429;
          throw err;
        },
      },
    };

    let caughtError: any = null;
    try {
      await generateWithFallback(mockAi, { contents: 'Halo' });
    } catch (e: any) {
      caughtError = e;
    }

    if (!caughtError || caughtError.status !== 429) {
      throw new Error(`Harusnya error 429 dilempar, tapi dapat: ${caughtError}`);
    }
    if (calls !== 1) {
      throw new Error(`Harusnya hanya 1 kali percobaan untuk error kuota 429, tapi terjadi ${calls} kali`);
    }
  });

  // 12. ensureClosedCodeBlocks - Otomatis menutup markdown code block gantung
  await test('12. ensureClosedCodeBlocks menutup codeblock gantung dan membiarkan teks yang sudah tertutup', async () => {
    const unclosed = 'Contoh kode:\n```dart\nvoid main() {\n  print("Hello");\n}';
    const fixed = ensureClosedCodeBlocks(unclosed);
    if (!fixed.endsWith('\n```')) {
      throw new Error(`Harusnya ditutup dengan backtick, hasil: ${fixed}`);
    }

    const closed = 'Contoh kode:\n```dart\nvoid main() {}\n```\nSelesai.';
    if (ensureClosedCodeBlocks(closed) !== closed) {
      throw new Error('Teks yang sudah berpasangan genap tidak boleh diubah');
    }

    if (ensureClosedCodeBlocks('') !== '') {
      throw new Error('String kosong harus tetap kosong');
    }
  });

  // 13. generateWithFallback - Retry tanpa thinkingConfig jika model menolak thinking
  await test('13. generateWithFallback otomatis retry tanpa thinkingConfig jika model menolak thinking', async () => {
    let callIndex = 0;
    const receivedConfigs: any[] = [];
    const mockAi = {
      models: {
        generateContent: async (cfg: any) => {
          callIndex++;
          receivedConfigs.push(cfg);
          if (callIndex === 1) {
            const err: any = new Error('Invalid parameter: ThinkingConfig is unsupported for this model');
            err.status = 400;
            throw err;
          }
          return { text: 'Success without thinking config' };
        },
      },
    };

    const res: any = await generateWithFallback(mockAi, {
      contents: 'Hitung sesuatu',
      config: {
        maxOutputTokens: 2048,
        thinkingConfig: { thinkingBudget: 512 },
      },
    });

    if (callIndex !== 2) {
      throw new Error(`Harusnya retry 2 kali, tapi dipanggil ${callIndex} kali`);
    }
    if (receivedConfigs[1]?.config?.thinkingConfig !== undefined) {
      throw new Error('Percobaan kedua seharusnya tidak menyertakan thinkingConfig');
    }
    if (res?.text !== 'Success without thinking config') {
      throw new Error(`Hasil tidak sesuai: ${res?.text}`);
    }
  });

  // 14. Validasi HUTAO_AI_SYSTEM_INSTRUCTION: Identitas, Larangan LaTeX & Tanda Dolar, Guardrail Pedagogik
  await test('14. HUTAO_AI_SYSTEM_INSTRUCTION memuat identitas Hutao-AI, larangan tanda dolar ($), dan instruksi Socratic', async () => {
    if (!HUTAO_AI_SYSTEM_INSTRUCTION || typeof HUTAO_AI_SYSTEM_INSTRUCTION !== 'string') {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak ditemukan atau bukan string');
    }

    // Identitas karakter harus ada
    if (!HUTAO_AI_SYSTEM_INSTRUCTION.includes('Hutao-AI')) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak mengandung nama identitas "Hutao-AI"');
    }

    // Larangan tanda dolar harus eksplisit
    if (!HUTAO_AI_SYSTEM_INSTRUCTION.includes('$m$') || !HUTAO_AI_SYSTEM_INSTRUCTION.toLowerCase().includes('dilarang')) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat aturan larangan notasi tanda dolar secara eksplisit');
    }

    // Larangan LaTeX harus ada
    if (!HUTAO_AI_SYSTEM_INSTRUCTION.includes('LaTeX') && !HUTAO_AI_SYSTEM_INSTRUCTION.includes('latex')) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak mengandung larangan LaTeX');
    }

    // Guardrail Socratic: larangan jawaban kuis langsung
    const hasSocratic =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('Socratic') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('langkah demi langkah') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('kunci jawaban');
    if (!hasSocratic) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat guardrail metode Socratic / bimbingan bertahap');
    }

    // Guardrail keamanan: larangan jailbreak
    const hasSecurity =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('jailbreak') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('Abaikan aturan') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('system prompt');
    if (!hasSecurity) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat guardrail keamanan / anti-jailbreak');
    }
  });

  // 15. Validasi larangan identitas lama "Farlean AI Tutor" dan pemisahan nama produk
  await test('15. HUTAO_AI_SYSTEM_INSTRUCTION melarang identitas "Farlean AI Tutor" dan memisahkan nama AI dari nama produk', async () => {
    // Instruksi WAJIB mengandung larangan menyebut diri sebagai "Farlean AI Tutor"
    const forbidsFarleanAiTutor =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('Farlean AI Tutor') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('DILARANG KERAS menyebut diri') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('LARANGAN MUTLAK');
    if (!forbidsFarleanAiTutor) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat larangan identitas "Farlean AI Tutor" secara eksplisit');
    }

    // Instruksi WAJIB memisahkan nama AI (Hutao-AI) dari nama produk (Farlean LMS)
    const separatesProductName =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('Farlean LMS') &&
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('Hutao-AI');
    if (!separatesProductName) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat pemisahan nama AI "Hutao-AI" dan nama produk "Farlean LMS"');
    }
  });

  // 16. Validasi pedoman anti-redundansi sapaan (stateless single-turn awareness)
  await test('16. HUTAO_AI_SYSTEM_INSTRUCTION memuat pedoman sapaan anti-redundan untuk endpoint stateless', async () => {
    // Instruksi harus membedakan kondisi sapaan murni vs pertanyaan materi
    const hasGreetingGuidance =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('sapaan') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('menanyakan identitas') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('JIKA pengguna');
    if (!hasGreetingGuidance) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat pedoman diferensiasi jenis pesan (sapaan vs pertanyaan materi)');
    }

    // Instruksi harus melarang perkenalan ulang saat pengguna langsung bertanya materi
    const hasNoRedundantIntro =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('DILARANG mengulang') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('jangan mengulang') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('JANGAN memperkenalkan diri lagi') ||
      HUTAO_AI_SYSTEM_INSTRUCTION.toLowerCase().includes('dilarang mengulang kalimat perkenalan');
    if (!hasNoRedundantIntro) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat aturan larangan pengulangan perkenalan diri pada pertanyaan materi');
    }
  });

  // 17. Validasi pedoman mode formal atas permintaan pengguna
  await test('17. HUTAO_AI_SYSTEM_INSTRUCTION memuat pedoman beralih ke mode formal saat diminta pengguna', async () => {
    const hasFormalMode =
      HUTAO_AI_SYSTEM_INSTRUCTION.includes('formal') &&
      (HUTAO_AI_SYSTEM_INSTRUCTION.includes('tanpa humor') ||
       HUTAO_AI_SYSTEM_INSTRUCTION.includes('tanpa interjeksi') ||
       HUTAO_AI_SYSTEM_INSTRUCTION.includes('tanpa bercanda') ||
       HUTAO_AI_SYSTEM_INSTRUCTION.includes('mode formal'));
    if (!hasFormalMode) {
      throw new Error('HUTAO_AI_SYSTEM_INSTRUCTION tidak memuat pedoman beralih ke mode formal saat pengguna memintanya');
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
