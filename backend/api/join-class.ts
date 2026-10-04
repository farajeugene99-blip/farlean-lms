import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth, FieldValue } from '../lib/firebaseAdmin';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi token pengirim
  const user = await verifyAuth(req, res);
  if (!user) return;

  const { classCode } = req.body;
  if (!classCode || typeof classCode !== 'string') {
    return res.status(400).json({ error: 'Kode kelas wajib diisi.' });
  }

  try {
    const normalizedCode = classCode.trim();

    // 2. Cari kelas berdasarkan kode unik
    const classQuery = await db
      .collection('classes')
      .where('code', '==', normalizedCode)
      .limit(1)
      .get();

    if (classQuery.empty) {
      return res.status(404).json({ error: 'Kelas dengan kode tersebut tidak ditemukan.' });
    }

    const classDoc = classQuery.docs[0];
    const classId = classDoc.id;
    const classData = classDoc.data();

    // 3. Baca profil pengguna di Firestore untuk memeriksa account_type
    const userDoc = await db.collection('users').doc(user.uid).get();
    const userData = userDoc.data();
    const accountType = userData?.account_type || 'UMUM';

    // Aturan Blueprint Farlean LMS:
    // MAHASISWA & DOSEN langsung aktif, akun UMUM statusnya pending
    const memberStatus = (accountType === 'MAHASISWA' || accountType === 'DOSEN')
      ? 'active'
      : 'pending';

    // 4. Daftarkan pengguna ke sub-koleksi classes/{classId}/members/{uid}
    const memberRef = db.collection('classes').doc(classId).collection('members').doc(user.uid);
    
    const existingMember = await memberRef.get();
    if (existingMember.exists && existingMember.data()?.status === 'active') {
      return res.status(400).json({ error: 'Anda sudah menjadi anggota aktif di kelas ini.' });
    }

    await memberRef.set(
      {
        display_name: userData?.name || user.email?.split('@')[0] || 'Anggota',
        account_type: accountType,
        status: memberStatus,
        joined_at: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );

    return res.status(200).json({
      success: true,
      classId,
      className: classData.name || 'Kelas Farlean LMS',
      status: memberStatus,
      message:
        memberStatus === 'active'
          ? 'Berhasil bergabung ke dalam kelas.'
          : 'Permintaan bergabung berhasil dikirim. Menunggu persetujuan Guru.',
    });
  } catch (error: any) {
    console.error('Error join-class:', error);
    return res.status(500).json({ error: 'Terjadi kesalahan pada server saat memproses kode kelas.' });
  }
}