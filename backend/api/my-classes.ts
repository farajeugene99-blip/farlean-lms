import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Auth Pengguna
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const role = (user as any).role || 'USER';
  const ownedClasses: any[] = [];
  const joinedClasses: any[] = [];
  const ownedIds = new Set<string>();

  try {
    // 2. Jika user adalah GURU atau ADMIN, ambil kelas yang dia kelola (Owned)
    if (role === 'GURU' || role === 'ADMIN') {
      const ownedSnap = await db
        .collection('classes')
        .where('teacher_id', '==', user.uid)
        .get();

      for (const doc of ownedSnap.docs) {
        const data = doc.data() || {};
        ownedIds.add(doc.id);
        ownedClasses.push({
          id: doc.id,
          name: data.name || 'Kelas Tanpa Nama',
          code: data.code || '',
          description: data.description || '',
          teacher_id: data.teacher_id || '',
          status: data.status || 'Active',
          created_at: data.created_at?.toDate ? data.created_at.toDate() : data.created_at,
          updated_at: data.updated_at?.toDate ? data.updated_at.toDate() : data.updated_at,
        });
      }
    }

    // 3. Ambil kelas tempat user terdaftar sebagai anggota (Joined)
    // Menghindari collectionGroup demi keamanan & kehandalan index
    const enrolledSnap = await db
      .collection('users')
      .doc(user.uid)
      .collection('enrolled_classes')
      .get();

    for (const enrolledDoc of enrolledSnap.docs) {
      const classId = enrolledDoc.id;
      // Jangan duplikasi kelas yang sudah ada di daftar owned
      if (ownedIds.has(classId)) continue;

      const enrolledData = enrolledDoc.data() || {};
      const classDoc = await db.collection('classes').doc(classId).get();

      if (classDoc.exists) {
        const classData = classDoc.data() || {};
        joinedClasses.push({
          id: classDoc.id,
          name: classData.name || 'Kelas Farlean LMS',
          code: classData.code || '',
          description: classData.description || '',
          teacher_id: classData.teacher_id || '',
          status: classData.status || 'Active',
          membership_status: enrolledData.status || 'active',
          created_at: classData.created_at?.toDate ? classData.created_at.toDate() : classData.created_at,
          updated_at: classData.updated_at?.toDate ? classData.updated_at.toDate() : classData.updated_at,
        });
      }
    }

    return res.status(200).json({
      success: true,
      owned: ownedClasses,
      joined: joinedClasses,
    });
  } catch (err: any) {
    console.error('Error my-classes:', err);
    return res.status(500).json({ error: 'Gagal memuat daftar kelas pengguna.' });
  }
}
