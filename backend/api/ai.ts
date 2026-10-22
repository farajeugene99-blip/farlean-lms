import type { VercelRequest, VercelResponse } from '@vercel/node';
import { GoogleGenAI } from '@google/genai';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

export const PRIMARY_MODEL = (process.env.GEMINI_MODEL || 'gemini-3.6-flash').replace(/^models\//, '').trim();

export function getFallbackModels(): string[] {
  const custom = process.env.GEMINI_MODEL
    ? [process.env.GEMINI_MODEL.replace(/^models\//, '').trim()]
    : [];
  const candidates = [
    ...custom,
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-3.8-flash',
    'gemini-3.5-flash-lite',
    'gemini-flash-lite-latest',
  ];
  return Array.from(new Set(candidates.filter(Boolean)));
}

export const FALLBACK_MODELS = getFallbackModels();

export function ensureClosedCodeBlocks(text: string): string {
  if (!text || typeof text !== 'string') return '';
  const fenceMatches = text.match(/```/g);
  if (fenceMatches && fenceMatches.length % 2 !== 0) {
    return `${text}\n\`\`\``;
  }
  return text;
}

export async function generateWithFallback(ai: any, promptConfig: any) {
  const models = getFallbackModels();
  let lastError: any;

  for (const modelName of models) {
    try {
      return await ai.models.generateContent({
        ...promptConfig,
        model: modelName,
      });
    } catch (err: any) {
      lastError = err;
      const errMsg = String(err?.message || err || '').toLowerCase();
      const status = Number(err?.status || err?.code || err?.error?.code || 0);

      // Jika model tertentu menolak thinkingConfig, coba sekali lagi tanpa thinkingConfig untuk model ini
      if (promptConfig?.config?.thinkingConfig && (errMsg.includes('thinking') || errMsg.includes('thinkingconfig') || errMsg.includes('unsupported field'))) {
        try {
          const { thinkingConfig, ...restConfig } = promptConfig.config;
          return await ai.models.generateContent({
            ...promptConfig,
            config: restConfig,
            model: modelName,
          });
        } catch (retryErr: any) {
          lastError = retryErr;
        }
      }

      // Lanjut ke model fallback berikutnya hanya jika model tidak ditemukan / deprecated / unsupported (404 / NOT_FOUND)
      const isNotFound =
        status === 404 ||
        errMsg.includes('404') ||
        errMsg.includes('not_found') ||
        errMsg.includes('not found') ||
        errMsg.includes('no longer available') ||
        errMsg.includes('is not supported') ||
        errMsg.includes('unsupported');

      if (isNotFound) {
        console.warn(`[AI] Model ${modelName} tidak tersedia (${status || errMsg}), mencoba fallback berikutnya...`);
        continue;
      }
      throw err;
    }
  }
  throw lastError;
}

export interface QuotaConfig {
  burstMax: number;
  burstWindowMs: number;
  dailyMax: number;
  dailyWindowMs: number;
}

export const AI_QUOTA_CONFIG: Record<string, Record<string, QuotaConfig>> = {
  USER: {
    tutor: {
      burstMax: 10,
      burstWindowMs: 15 * 60 * 1000,
      dailyMax: 30,
      dailyWindowMs: 24 * 60 * 60 * 1000,
    },
  },
  GURU: {
    tutor: {
      burstMax: 20,
      burstWindowMs: 15 * 60 * 1000,
      dailyMax: 100,
      dailyWindowMs: 24 * 60 * 60 * 1000,
    },
    'video-description': {
      burstMax: 5,
      burstWindowMs: 15 * 60 * 1000,
      dailyMax: 25,
      dailyWindowMs: 24 * 60 * 60 * 1000,
    },
  },
  ADMIN: {
    tutor: {
      burstMax: 30,
      burstWindowMs: 15 * 60 * 1000,
      dailyMax: 200,
      dailyWindowMs: 24 * 60 * 60 * 1000,
    },
    'video-description': {
      burstMax: 30,
      burstWindowMs: 15 * 60 * 1000,
      dailyMax: 200,
      dailyWindowMs: 24 * 60 * 60 * 1000,
    },
  },
};

export function getAiQuotaConfig(role: string, feature: string): QuotaConfig {
  const roleConfig = AI_QUOTA_CONFIG[role] || AI_QUOTA_CONFIG.USER;
  const config = roleConfig[feature];
  if (config) return config;
  return {
    burstMax: 10,
    burstWindowMs: 15 * 60 * 1000,
    dailyMax: 30,
    dailyWindowMs: 24 * 60 * 60 * 1000,
  };
}

export interface RateLimitResult {
  allowed: boolean;
  remainingBurst: number;
  remainingDaily: number;
  remainingQuota: number;
  resetAt?: number;
  retryAfterSeconds?: number;
  reason?: 'burst' | 'daily';
}

export async function checkRateLimit(
  docId: string,
  config: QuotaConfig
): Promise<RateLimitResult> {
  const rateLimitRef = db.collection('rate_limits').doc(docId);
  let result: RateLimitResult = {
    allowed: true,
    remainingBurst: config.burstMax,
    remainingDaily: config.dailyMax,
    remainingQuota: Math.min(config.burstMax, config.dailyMax),
  };

  await db.runTransaction(async (transaction) => {
    const now = Date.now();
    const rateDoc = await transaction.get(rateLimitRef);
    let burstCount = 0;
    let burstResetAt = now + config.burstWindowMs;
    let dailyCount = 0;
    let dailyResetAt = now + config.dailyWindowMs;

    if (rateDoc.exists) {
      const data = rateDoc.data() || {};

      const storedBurstReset = typeof data.burstResetAt === 'number'
        ? data.burstResetAt
        : (data.window_start?.toMillis ? data.window_start.toMillis() + config.burstWindowMs : 0);

      if (storedBurstReset > now) {
        burstCount = typeof data.burstCount === 'number' ? data.burstCount : (data.attempts || 0);
        burstResetAt = storedBurstReset;
      } else {
        burstCount = 0;
        burstResetAt = now + config.burstWindowMs;
      }

      const storedDailyReset = typeof data.dailyResetAt === 'number' ? data.dailyResetAt : 0;
      if (storedDailyReset > now) {
        dailyCount = typeof data.dailyCount === 'number' ? data.dailyCount : burstCount;
        dailyResetAt = storedDailyReset;
      } else {
        dailyCount = 0;
        dailyResetAt = now + config.dailyWindowMs;
      }

      if (burstCount >= config.burstMax) {
        const retryAfterSeconds = Math.max(1, Math.ceil((burstResetAt - now) / 1000));
        result = {
          allowed: false,
          remainingBurst: 0,
          remainingDaily: Math.max(0, config.dailyMax - dailyCount),
          remainingQuota: 0,
          resetAt: burstResetAt,
          retryAfterSeconds,
          reason: 'burst',
        };
        return;
      }

      if (dailyCount >= config.dailyMax) {
        const retryAfterSeconds = Math.max(1, Math.ceil((dailyResetAt - now) / 1000));
        result = {
          allowed: false,
          remainingBurst: Math.max(0, config.burstMax - burstCount),
          remainingDaily: 0,
          remainingQuota: 0,
          resetAt: dailyResetAt,
          retryAfterSeconds,
          reason: 'daily',
        };
        return;
      }
    }

    const newBurstCount = burstCount + 1;
    const newDailyCount = dailyCount + 1;

    transaction.set(
      rateLimitRef,
      {
        burstCount: newBurstCount,
        burstResetAt,
        dailyCount: newDailyCount,
        dailyResetAt,
        attempts: newBurstCount,
        window_start: new Date(burstResetAt - config.burstWindowMs),
        last_request_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    const remainingBurst = config.burstMax - newBurstCount;
    const remainingDaily = config.dailyMax - newDailyCount;

    result = {
      allowed: true,
      remainingBurst,
      remainingDaily,
      remainingQuota: Math.min(remainingBurst, remainingDaily),
    };
  });

  return result;
}

async function isActivelyTakingExam(userId: string): Promise<boolean> {
  const attemptsSnap = await db.collection('attempts').where('user_id', '==', userId).get();
  if (attemptsSnap.empty) return false;

  const now = Date.now();
  for (const doc of attemptsSnap.docs) {
    const data = doc.data() || {};
    if (data.status === 'in_progress') {
      const startedMs = data.started_at?.toMillis
        ? data.started_at.toMillis()
        : (data.started_at ? new Date(data.started_at).getTime() : now);
      const durationMinutes = (typeof data.duration_minutes === 'number' && data.duration_minutes > 0)
        ? data.duration_minutes
        : 60;
      const expiresMs = startedMs + durationMinutes * 60 * 1000;

      if (now < expiresMs) {
        return true;
      }
    }
  }
  return false;
}

export function extractDeltaPlainText(rawContent: any): string {
  if (!rawContent) return '';
  let parsed = rawContent;
  if (typeof rawContent === 'string') {
    try {
      parsed = JSON.parse(rawContent);
    } catch {
      return rawContent.trim();
    }
  }
  const ops = Array.isArray(parsed) ? parsed : (Array.isArray(parsed?.ops) ? parsed.ops : null);
  if (ops) {
    return ops
      .map((op: any) => (typeof op.insert === 'string' ? op.insert : ''))
      .join('')
      .trim();
  }
  if (typeof parsed === 'string') return parsed.trim();
  return '';
}

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ success: false, error: 'Method Not Allowed', message: 'Method Not Allowed' });
  }

  // 1. Verifikasi Autentikasi Pengguna
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const role = (user as any).role || 'USER';
  const action = (req.query.__action as string) || req.body?.action || 'tutor';

  // 2. Handler: Draf Deskripsi Video (Khusus GURU / ADMIN)
  if (action === 'video-description') {
    if (role !== 'GURU' && role !== 'ADMIN') {
      return res.status(403).json({
        error: 'Akses ditolak: Hanya Pengajar atau Admin yang berhak menggunakan generator deskripsi video.',
      });
    }

    // Rate Limit Kuota Dual-Tier (Burst 15 Menit & Daily 24 Jam)
    const quotaConfig = getAiQuotaConfig(role, 'video-description');
    const rateLimit = await checkRateLimit(`ai_video_${user.uid}`, quotaConfig);
    if (!rateLimit.allowed) {
      if (typeof res.setHeader === 'function' && rateLimit.retryAfterSeconds) {
        res.setHeader('Retry-After', String(rateLimit.retryAfterSeconds));
      }
      const resetMinutes = Math.max(1, Math.ceil((rateLimit.retryAfterSeconds || 60) / 60));
      const errorMessage = rateLimit.reason === 'daily'
        ? `Batas kuota harian AI Video Generator tercapai (${quotaConfig.dailyMax} draf / 24 jam). Kuota harian Anda akan direset dalam ${resetMinutes} menit.`
        : `Batas penggunaan AI Video Generator tercapai (${quotaConfig.burstMax} draf / 15 menit). Harap tunggu ${rateLimit.retryAfterSeconds} detik sebelum mencoba kembali.`;

      return res.status(429).json({
        success: false,
        error: errorMessage,
        message: errorMessage,
        remainingBurst: rateLimit.remainingBurst,
        remainingDaily: rateLimit.remainingDaily,
        remainingQuota: 0,
        resetAt: rateLimit.resetAt,
        retryAfterSeconds: rateLimit.retryAfterSeconds,
        reason: rateLimit.reason,
      });
    }

    const { title, courseName, meetingTitle, keywords, existingDescription } = req.body || {};
    if (!title && !meetingTitle) {
      return res.status(400).json({ error: 'Judul video atau judul pertemuan wajib diisi.' });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({
        success: false,
        error: 'Layanan AI Assistant sedang tidak dapat diakses sementara karena konfigurasi server belum lengkap (GEMINI_API_KEY).',
        message: 'Layanan AI Assistant sedang tidak dapat diakses sementara karena konfigurasi server belum lengkap (GEMINI_API_KEY).',
      });
    }

    try {
      const ai = new GoogleGenAI({ apiKey });
      const systemInstruction = `Kamu adalah Asisten Kurikulum Farlean LMS. Tugasmu adalah menyusun draf deskripsi video pembelajaran yang terstruktur, edukatif, dan menarik bagi mahasiswa. Gunakan Bahasa Indonesia yang baik dan baku dengan format Markdown yang rapi.
Format output memuat:
## 1. Ringkasan Singkat Isi Video
Jelaskan gambaran umum materi pembelajaran dan konteks penerapannya.
## 2. Tujuan Pembelajaran
Sajikan capaian pembelajaran yang diharapkan dalam bentuk bullet points.
## 3. Poin-Poin Penting
Uraikan konsep atau subtopik utama secara jelas dengan cetak tebal pada istilah kunci.
## 4. Pertanyaan Refleksi / Diskusi
Sajikan 2-3 pertanyaan pemantik diskusi untuk menguji pemahaman mahasiswa.

PENTING: Jangan gunakan format LaTeX ($...$ atau \\frac{}{}). Gunakan simbol matematika Unicode yang mudah dibaca atau teks biasa.`;

      const prompt = `Buatkan draf deskripsi video pembelajaran berdasarkan metadata berikut:
- Judul Video/Materi: ${title || meetingTitle}
- Mata Kuliah/Kelas: ${courseName || 'Umum'}
- Pertemuan: ${meetingTitle || '-'}
- Kata Kunci: ${keywords || '-'}
- Draf Awal (jika ada): ${existingDescription || '-'}`;

      const response = await generateWithFallback(ai, {
        contents: prompt,
        config: {
          systemInstruction,
          maxOutputTokens: 2048,
          temperature: 0.4,
          thinkingConfig: {
            thinkingBudget: 512,
          },
        },
      });

      const draftDescription = ensureClosedCodeBlocks(response.text ?? '');
      return res.status(200).json({
        success: true,
        draftDescription,
        remainingQuota: rateLimit.remainingQuota,
        remainingBurst: rateLimit.remainingBurst,
        remainingDaily: rateLimit.remainingDaily,
      });
    } catch (e: any) {
      console.error('[AI Video Description Error]:', e);
      return res.status(502).json({
        success: false,
        error: 'Gagal memproses draf deskripsi AI saat ini. Silakan coba lagi beberapa saat lagi.',
        message: 'Gagal memproses draf deskripsi AI saat ini. Silakan coba lagi beberapa saat lagi.',
      });
    }
  }

  // 3. Handler: AI Tutor Pintar (Mahasiswa & Staf)
  if (action === 'tutor') {
    // A. Exam Guardrail: Blokir jika mahasiswa sedang aktif menempuh kuis
    if (role === 'USER') {
      const activeExam = await isActivelyTakingExam(user.uid);
      if (activeExam) {
        return res.status(403).json({
          error: 'Fitur AI Tutor dinonaktifkan sementara saat Anda sedang menempuh sesi kuis/ujian.',
          isExamLocked: true,
        });
      }
    }

    // B. Rate Limit Kuota Dual-Tier (Burst 15 Menit & Daily 24 Jam)
    const quotaConfig = getAiQuotaConfig(role, 'tutor');
    const rateLimit = await checkRateLimit(`ai_tutor_${user.uid}`, quotaConfig);
    if (!rateLimit.allowed) {
      if (typeof res.setHeader === 'function' && rateLimit.retryAfterSeconds) {
        res.setHeader('Retry-After', String(rateLimit.retryAfterSeconds));
      }
      const resetMinutes = Math.max(1, Math.ceil((rateLimit.retryAfterSeconds || 60) / 60));
      const errorMessage = rateLimit.reason === 'daily'
        ? `Batas kuota harian AI Tutor tercapai (${quotaConfig.dailyMax} pertanyaan / 24 jam). Kuota harian Anda akan direset dalam ${resetMinutes} menit.`
        : `Batas kuota AI Tutor tercapai (${quotaConfig.burstMax} pertanyaan / 15 menit). Harap tunggu ${rateLimit.retryAfterSeconds} detik sebelum bertanya kembali.`;

      return res.status(429).json({
        success: false,
        error: errorMessage,
        message: errorMessage,
        remainingBurst: rateLimit.remainingBurst,
        remainingDaily: rateLimit.remainingDaily,
        remainingQuota: 0,
        resetAt: rateLimit.resetAt,
        retryAfterSeconds: rateLimit.retryAfterSeconds,
        reason: rateLimit.reason,
      });
    }

    const { prompt: userPrompt, classId, meetingId, materiId } = req.body || {};
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
      return res.status(400).json({ error: 'Pertanyaan (prompt) tidak boleh kosong.' });
    }

    if (userPrompt.trim().length > 1000) {
      return res.status(400).json({ error: 'Pertanyaan maksimal 1000 karakter.' });
    }

    // C. Validasi Otorisasi Konteks Pembelajaran (Class, Meeting, Materi)
    let contextTitle = '';
    let contextPlainText = '';

    if (classId && typeof classId === 'string' && classId.trim().length > 0) {
      const cleanClassId = classId.trim();
      const classDoc = await db.collection('classes').doc(cleanClassId).get();
      if (!classDoc.exists) {
        return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
      }

      const classData = classDoc.data() || {};
      const isTeacher = classData.teacher_id === user.uid;

      if (role !== 'ADMIN' && !isTeacher) {
        const memberDoc = await db
          .collection('classes')
          .doc(cleanClassId)
          .collection('members')
          .doc(user.uid)
          .get();

        if (!memberDoc.exists || memberDoc.data()?.status !== 'active') {
          return res.status(403).json({
            error: 'Akses ditolak: Anda bukan anggota aktif kelas ini.',
          });
        }
      }

      // Verifikasi pertemuan (jika disediakan)
      let resolvedMateriId = materiId && typeof materiId === 'string' ? materiId.trim() : null;

      if (meetingId && typeof meetingId === 'string' && meetingId.trim().length > 0) {
        const cleanMeetingId = meetingId.trim();
        const meetingDoc = await db.collection('meetings').doc(cleanMeetingId).get();
        if (!meetingDoc.exists) {
          return res.status(404).json({ error: 'Pertemuan tidak ditemukan.' });
        }

        const meetingData = meetingDoc.data() || {};
        if (meetingData.class_id !== cleanClassId) {
          return res.status(403).json({
            error: 'Akses ditolak: Pertemuan tidak terdaftar pada kelas ini.',
          });
        }

        // Mahasiswa tidak boleh mengakses konteks materi dari pertemuan yang terkunci/Scheduled/Draft
        if (role !== 'ADMIN' && !isTeacher) {
          const meetingStatus = (meetingData.status || '').toString().toLowerCase();
          if (meetingStatus === 'scheduled' || meetingStatus === 'draft') {
            return res.status(403).json({
              error: 'Akses ditolak: Pertemuan ini masih berstatus terjadwal atau terkunci.',
            });
          }
        }

        if (!resolvedMateriId && meetingData.materi_id) {
          resolvedMateriId = meetingData.materi_id;
        }
      }

      // Verifikasi materi (jika disediakan atau didapat dari pertemuan)
      if (resolvedMateriId) {
        const materiDoc = await db.collection('materials').doc(resolvedMateriId).get();
        if (!materiDoc.exists) {
          return res.status(404).json({ error: 'Materi tidak ditemukan.' });
        }

        const materiData = materiDoc.data() || {};
        if (materiData.class_id !== cleanClassId) {
          return res.status(403).json({
            error: 'Akses ditolak: Materi tidak terdaftar pada kelas ini.',
          });
        }

        if (role !== 'ADMIN' && !isTeacher && materiData.status !== 'Published') {
          return res.status(403).json({
            error: 'Akses ditolak: Materi belum dipublikasikan.',
          });
        }

        contextTitle = materiData.title || '';
        const rawContent = materiData.content;
        const extracted = extractDeltaPlainText(rawContent);
        const MAX_CONTEXT_CHARS = 8000;
        contextPlainText = extracted.length > MAX_CONTEXT_CHARS
          ? extracted.slice(0, MAX_CONTEXT_CHARS) + '\n...[Konten dipotong untuk batas konteks]'
          : extracted;
      }
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({
        success: false,
        error: 'Layanan AI Assistant sedang tidak dapat diakses sementara karena konfigurasi server belum lengkap (GEMINI_API_KEY).',
        message: 'Layanan AI Assistant sedang tidak dapat diakses sementara karena konfigurasi server belum lengkap (GEMINI_API_KEY).',
      });
    }

    try {
      const ai = new GoogleGenAI({ apiKey });
      let systemInstruction = `Kamu adalah Farlean AI Tutor, asisten belajar cerdas dan ramah untuk mahasiswa dan dosen pada Farlean LMS.
Prinsip interaksimu:
1. Jelaskan konsep secara terstruktur, jelas, komprehensif, dan mudah dipahami di layar mobile (hindari jawaban yang terlalu pendek/terpotong, namun tetap padat dan to-the-point).
2. Gunakan format Markdown yang rapi: gunakan heading ringan (###), poin-poin bullet list (-), cetak tebal (**istilah penting**) untuk konsep kunci, serta code block (\`\`\`bahasa ... \`\`\`) jika menyajikan kode program atau algoritma.
3. Berikan analogi dunia nyata atau contoh praktis singkat sebelum memberikan pertanyaan pemantik atau bimbingan penalaran bertahap (metode Socratic).
4. Dilarang keras memberikan kunci jawaban langsung jika pengguna tampak meminta jawaban kuis/ujian. Bimbing langkah demi langkah agar siswa memahami konsepnya.
5. PENTING - FORMAT MATEMATIKA / RUMUS: Dilarang menggunakan notasi LaTeX ($...$ atau $$...$$ atau \\frac{}{}) karena layar aplikasi tidak mendukung LaTeX. Gunakan format Markdown standar dan simbol matematika Unicode yang mudah dibaca (seperti ×, ÷, ², ³, √, ≥, ≤, ±, →, π) atau penjelasan teks biasa.
6. Gunakan Bahasa Indonesia yang ramah, santun, akademis, dan memotivasi belajar.`;

      if (contextTitle || contextPlainText) {
        systemInstruction += `\n\nKonteks Pembelajaran yang Sedang Dipelajari Mahasiswa:
Judul Materi: ${contextTitle || '-'}
Isi Dokumen Materi:
"""
${contextPlainText}
"""
Instruksi Tambahan:
Gunakan konteks materi di atas untuk menjawab dan membimbing mahasiswa secara kontekstual, tepat sasaran, dan relevan dengan kurikulum kelas tersebut, tanpa memberikan kunci jawaban tes/kuis langsung. Tetap patuhi aturan larangan LaTeX dan format Markdown yang rapi.`;
      }

      const response = await generateWithFallback(ai, {
        contents: userPrompt.trim(),
        config: {
          systemInstruction,
          maxOutputTokens: 2048,
          temperature: 0.5,
          thinkingConfig: {
            thinkingBudget: 512,
          },
        },
      });

      const reply = ensureClosedCodeBlocks(response.text ?? '');
      return res.status(200).json({
        success: true,
        reply,
        remainingQuota: rateLimit.remainingQuota,
        remainingBurst: rateLimit.remainingBurst,
        remainingDaily: rateLimit.remainingDaily,
      });
    } catch (e: any) {
      console.error('[AI Tutor Error]:', e);
      return res.status(502).json({
        success: false,
        error: 'Gagal memproses jawaban AI Tutor saat ini. Silakan coba lagi beberapa saat lagi.',
        message: 'Gagal memproses jawaban AI Tutor saat ini. Silakan coba lagi beberapa saat lagi.',
      });
    }
  }

  return res.status(400).json({ error: `Aksi AI tidak dikenal: ${action}` });
}
