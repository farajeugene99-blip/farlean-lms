import type { VercelRequest, VercelResponse } from '@vercel/node';
import { GoogleGenAI } from '@google/genai';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

const TUTOR_WINDOW_MS = 15 * 60 * 1000;
const TUTOR_MAX_REQUESTS = 10;

const VIDEO_WINDOW_MS = 15 * 60 * 1000;
const VIDEO_MAX_REQUESTS = 5;

async function checkRateLimit(
  docId: string,
  maxAttempts: number,
  windowMs: number
): Promise<{ allowed: boolean; remaining: number }> {
  const rateLimitRef = db.collection('rate_limits').doc(docId);
  let allowed = true;
  let remaining = maxAttempts;

  await db.runTransaction(async (transaction) => {
    const now = Date.now();
    const rateDoc = await transaction.get(rateLimitRef);
    let attempts = 0;
    let windowStart = now;

    if (rateDoc.exists) {
      const data = rateDoc.data() || {};
      const lastStart = data.window_start?.toMillis
        ? data.window_start.toMillis()
        : (data.window_start || 0);

      if (now - lastStart < windowMs) {
        attempts = data.attempts || 0;
        windowStart = lastStart;
        if (attempts >= maxAttempts) {
          allowed = false;
          remaining = 0;
          return;
        }
      } else {
        attempts = 0;
        windowStart = now;
      }
    }

    transaction.set(
      rateLimitRef,
      {
        attempts: attempts + 1,
        window_start: typeof windowStart === 'number' ? new Date(windowStart) : windowStart,
        last_request_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
    remaining = maxAttempts - (attempts + 1);
  });

  return { allowed, remaining };
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

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
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

    // Rate Limit Kuota Dosen (5 request / 15 menit)
    const { allowed, remaining } = await checkRateLimit(
      `ai_video_${user.uid}`,
      VIDEO_MAX_REQUESTS,
      VIDEO_WINDOW_MS
    );
    if (!allowed) {
      return res.status(429).json({
        error: 'Batas penggunaan AI Video Generator tercapai (5 request / 15 menit). Silakan coba lagi nanti.',
      });
    }

    const { title, courseName, meetingTitle, keywords, existingDescription } = req.body || {};
    if (!title && !meetingTitle) {
      return res.status(400).json({ error: 'Judul video atau judul pertemuan wajib diisi.' });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({
        error: 'Layanan AI belum dikonfigurasi di server (GEMINI_API_KEY tidak ditemukan).',
      });
    }

    try {
      const ai = new GoogleGenAI({ apiKey });
      const systemInstruction = `Kamu adalah Asisten Kurikulum Farlean LMS. Tugasmu adalah menyusun draf deskripsi video pembelajaran yang terstruktur, edukatif, dan menarik bagi mahasiswa. Gunakan Bahasa Indonesia yang baik dan baku. Format output memuat:
1. Ringkasan Singkat Isi Video
2. Tujuan Pembelajaran
3. Poin-Poin Penting
4. Pertanyaan Refleksi / Diskusi`;

      const prompt = `Buatkan draf deskripsi video pembelajaran berdasarkan metadata berikut:
- Judul Video/Materi: ${title || meetingTitle}
- Mata Kuliah/Kelas: ${courseName || 'Umum'}
- Pertemuan: ${meetingTitle || '-'}
- Kata Kunci: ${keywords || '-'}
- Draf Awal (jika ada): ${existingDescription || '-'}`;

      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: prompt,
        config: {
          systemInstruction,
          maxOutputTokens: 800,
          temperature: 0.4,
        },
      });

      const draftDescription = response.text ?? '';
      return res.status(200).json({
        success: true,
        draftDescription,
        remainingQuota: remaining,
      });
    } catch (e: any) {
      console.error('Gemini video description error:', e);
      return res.status(500).json({
        error: `Gagal memproses draf deskripsi AI: ${e.message || e}`,
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

    // B. Rate Limit Kuota Mahasiswa (10 prompt / 15 menit)
    const { allowed, remaining } = await checkRateLimit(
      `ai_tutor_${user.uid}`,
      TUTOR_MAX_REQUESTS,
      TUTOR_WINDOW_MS
    );
    if (!allowed) {
      return res.status(429).json({
        error: 'Batas kuota AI Tutor tercapai (10 pertanyaan / 15 menit). Harap tunggu beberapa saat sebelum bertanya kembali.',
      });
    }

    const { prompt: userPrompt } = req.body || {};
    if (!userPrompt || typeof userPrompt !== 'string' || userPrompt.trim().length === 0) {
      return res.status(400).json({ error: 'Pertanyaan (prompt) tidak boleh kosong.' });
    }

    if (userPrompt.trim().length > 1000) {
      return res.status(400).json({ error: 'Pertanyaan maksimal 1000 karakter.' });
    }

    const apiKey = process.env.GEMINI_API_KEY;
    if (!apiKey) {
      return res.status(503).json({
        error: 'Layanan AI belum dikonfigurasi di server (GEMINI_API_KEY tidak ditemukan).',
      });
    }

    try {
      const ai = new GoogleGenAI({ apiKey });
      const systemInstruction = `Kamu adalah Farlean AI Tutor, asisten belajar cerdas dan ramah untuk mahasiswa dan dosen pada Farlean LMS.
Prinsipmu:
1. Jelaskan konsep dengan metode Socratic (membimbing penalaran bertahap, bukan sekadar memberi jawaban instan).
2. Dilarang memberikan kunci jawaban tes/ujian langsung jika pengguna tampak meminta jawaban kuis.
3. Berikan contoh kode praktis atau analogi dunia nyata jika relevan.
4. Gunakan Bahasa Indonesia yang ramah, sopan, dan jelas.`;

      const response = await ai.models.generateContent({
        model: 'gemini-2.5-flash',
        contents: userPrompt.trim(),
        config: {
          systemInstruction,
          maxOutputTokens: 800,
          temperature: 0.5,
        },
      });

      const reply = response.text ?? '';
      return res.status(200).json({
        success: true,
        reply,
        remainingQuota: remaining,
      });
    } catch (e: any) {
      console.error('Gemini tutor error:', e);
      return res.status(500).json({
        error: `Gagal memproses jawaban AI Tutor: ${e.message || e}`,
      });
    }
  }

  return res.status(400).json({ error: `Aksi AI tidak dikenal: ${action}` });
}
