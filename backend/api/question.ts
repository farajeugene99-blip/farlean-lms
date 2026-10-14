import type { VercelRequest, VercelResponse } from '@vercel/node';
import saveQuestionHandler from './_handlers/save-question';
import deleteQuestionHandler from './_handlers/delete-question';

/**
 * Dispatcher untuk Endpoint Domain Soal (/api/question)
 *
 * Mengonsolidasikan:
 * - /api/save-question -> saveQuestionHandler
 * - /api/delete-question -> deleteQuestionHandler
 *
 * Strategi Penentuan Aksi:
 * 1. Query parameter eksplisit: ?__action=save-question ATAU ?__action=delete-question (dari vercel.json rewrites)
 * 2. Fallback req.url: memeriksa kecocokan string URL
 * 3. Fallback signature payload body
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const action = (req.query.__action || req.query.action) as string | undefined;
  const url = req.url || '';

  if (action === 'delete-question' || url.includes('delete-question')) {
    return deleteQuestionHandler(req, res);
  }

  if (action === 'save-question' || url.includes('save-question')) {
    return saveQuestionHandler(req, res);
  }

  // Fallback berdasarkan signature body
  const body = req.body || {};
  if (body.testId && body.qid && !body.options && !body.text) {
    return deleteQuestionHandler(req, res);
  }

  // Default ke save-question jika memiliki text atau options
  if (body.text !== undefined || body.options !== undefined || body.testId !== undefined) {
    return saveQuestionHandler(req, res);
  }

  return res.status(400).json({
    error: 'Aksi soal tidak valid atau tidak dikenali pada dispatcher /api/question.',
  });
}
