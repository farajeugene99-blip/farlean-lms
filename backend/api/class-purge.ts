import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth } from '../lib/firebaseAdmin';
import { applyCors } from '../lib/cors';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Auth
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  // 2. Proteksi Wewenang Ketat: HANYA ADMIN yang boleh menghapus kelas secara permanen
  const role = (user as any).role || 'USER';
  if (role !== 'ADMIN') {
    return res.status(403).json({
      error: 'Akses ditolak: Penghapusan permanen kelas hanya dapat dilakukan oleh Admin sistem.',
    });
  }

  // Proteksi Lingkungan Produksi: Cegah pemanggilan destruktif tak sengaja tanpa flag izin server
  const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production';
  if (isProduction && process.env.ALLOW_CLASS_PURGE !== 'true') {
    return res.status(403).json({
      error: 'Akses ditolak: Penghapusan kelas dinonaktifkan di lingkungan produksi (ALLOW_CLASS_PURGE).',
    });
  }

  const { classId, force = false } = req.body || {};
  if (!classId || typeof classId !== 'string') {
    return res.status(400).json({ error: 'classId wajib diisi.' });
  }

  const cleanClassId = classId.trim();

  try {
    const classDoc = await db.collection('classes').doc(cleanClassId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
    }

    const classData = classDoc.data() || {};
    const classCode = classData.code;

    // 3. Kebijakan Anti-Orphan: Periksa apakah kelas masih memiliki anggota atau konten aktif
    if (!force) {
      const membersSnap = await db.collection('classes').doc(cleanClassId).collection('members').get();
      if (membersSnap.size > 0) {
        return res.status(400).json({
          error: `Gagal menghapus: Kelas masih memiliki ${membersSnap.size} anggota terdaftar. Keluarkan anggota atau arsipkan kelas terlebih dahulu.`,
        });
      }

      const meetingsSnap = await db.collection('meetings').where('class_id', '==', cleanClassId).limit(1).get();
      if (!meetingsSnap.empty) {
        return res.status(400).json({
          error: 'Gagal menghapus: Kelas masih memiliki pertemuan/materi aktif. Hapus pertemuan terlebih dahulu.',
        });
      }
    }

    // 4. Hapus Dokumen Kelas, Subkoleksi Members, dan Index Kode Kelas
    const batch = db.batch();

    // Hapus class_codes mapping
    if (classCode) {
      const codeRef = db.collection('class_codes').doc(classCode);
      batch.delete(codeRef);
    }

    // Hapus members subcollection
    const allMembers = await db.collection('classes').doc(cleanClassId).collection('members').get();
    for (const mDoc of allMembers.docs) {
      batch.delete(mDoc.ref);
    }

    // Hapus dokumen kelas utama
    batch.delete(classDoc.ref);

    await batch.commit();

    return res.status(200).json({
      success: true,
      message: `Kelas '${classData.name}' (${cleanClassId}) berhasil dihapus permanen oleh Admin.`,
    });
  } catch (err: any) {
    console.error('Error class-purge:', err);
    return res.status(500).json({ error: 'Terjadi kesalahan pada server saat menghapus kelas.' });
  }
}
