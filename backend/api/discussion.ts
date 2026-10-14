import type { VercelRequest, VercelResponse } from '@vercel/node';
import discussionThreadHandler from './_handlers/discussion-thread';
import discussionReplyHandler from './_handlers/discussion-reply';

/**
 * Dispatcher untuk Endpoint Domain Forum Diskusi (/api/discussion)
 *
 * Mengonsolidasikan:
 * - /api/discussion-thread -> discussionThreadHandler
 * - /api/discussion-reply -> discussionReplyHandler
 *
 * Strategi Penentuan Aksi:
 * 1. Query parameter eksplisit: ?__action=discussion-thread ATAU ?__action=discussion-reply
 * 2. Fallback req.url: memeriksa kecocokan string URL
 * 3. Fallback signature payload body
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const action = (req.query.__action || req.query.action) as string | undefined;
  const url = req.url || '';

  if (action === 'discussion-reply' || action === 'reply' || url.includes('discussion-reply')) {
    return discussionReplyHandler(req, res);
  }

  if (action === 'discussion-thread' || action === 'thread' || url.includes('discussion-thread')) {
    return discussionThreadHandler(req, res);
  }

  // Fallback berdasarkan signature body
  const body = req.body || {};
  if (body.discussionId !== undefined) {
    return discussionReplyHandler(req, res);
  }

  if (body.classId !== undefined && body.title !== undefined) {
    return discussionThreadHandler(req, res);
  }

  return res.status(400).json({
    error: 'Aksi diskusi tidak valid atau tidak dikenali pada dispatcher /api/discussion.',
  });
}
