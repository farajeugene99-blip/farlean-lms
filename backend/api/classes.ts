import type { VercelRequest, VercelResponse } from '@vercel/node';
import createClassHandler from './_handlers/create-class';
import myClassesHandler from './_handlers/my-classes';
import classMembersHandler from './_handlers/class-members';
import classPurgeHandler from './_handlers/class-purge';

/**
 * Dispatcher untuk Endpoint Domain Kelas (/api/classes)
 *
 * Mengonsolidasikan:
 * - /api/create-class  -> createClassHandler
 * - /api/my-classes    -> myClassesHandler
 * - /api/class-members -> classMembersHandler
 * - /api/class-purge   -> classPurgeHandler
 *
 * Strategi Penentuan Aksi:
 * 1. Query parameter eksplisit: ?__action=create-class | my-classes | class-members | class-purge
 * 2. Fallback req.url: memeriksa kecocokan string URL
 * 3. Fallback method HTTP & signature payload
 */
export default async function handler(req: VercelRequest, res: VercelResponse) {
  const action = (req.query.__action || req.query.action) as string | undefined;
  const url = req.url || '';

  if (action === 'create-class' || url.includes('create-class')) {
    return createClassHandler(req, res);
  }

  if (action === 'my-classes' || url.includes('my-classes')) {
    return myClassesHandler(req, res);
  }

  if (action === 'class-members' || url.includes('class-members')) {
    return classMembersHandler(req, res);
  }

  if (action === 'class-purge' || url.includes('class-purge')) {
    return classPurgeHandler(req, res);
  }

  // Fallback berdasarkan method & signature
  if (req.method === 'GET') {
    if (req.query.classId) {
      return classMembersHandler(req, res);
    }
    return myClassesHandler(req, res);
  }

  if (req.method === 'POST') {
    const body = req.body || {};
    if (body.force !== undefined || (body.classId && !body.name)) {
      return classPurgeHandler(req, res);
    }
    if (body.name !== undefined) {
      return createClassHandler(req, res);
    }
  }

  return res.status(400).json({
    error: 'Aksi kelas tidak valid atau tidak dikenali pada dispatcher /api/classes.',
  });
}
