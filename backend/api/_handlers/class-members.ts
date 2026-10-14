import type { VercelRequest, VercelResponse } from '@vercel/node';
import { db, verifyAuth } from '../../lib/firebaseAdmin';
import { applyCors } from '../../lib/cors';

export default async function handler(req: VercelRequest, res: VercelResponse) {
  if (applyCors(req, res)) return;

  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method Not Allowed' });
  }

  // 1. Verifikasi Auth
  const user = await verifyAuth(req, res, { requireEmailVerified: true });
  if (!user) return;

  const { classId } = req.query || {};
  if (!classId || typeof classId !== 'string') {
    return res.status(400).json({ error: 'classId query parameter wajib disertakan.' });
  }

  const cleanClassId = classId.trim();

  try {
    const classDoc = await db.collection('classes').doc(cleanClassId).get();
    if (!classDoc.exists) {
      return res.status(404).json({ error: 'Kelas tidak ditemukan.' });
    }
    const classData = classDoc.data() || {};

    const role = (user as any).role || 'USER';
    const isOwnerOrAdmin = role === 'ADMIN' || (role === 'GURU' && classData.teacher_id === user.uid);

    // 2. Jika bukan owner atau admin, pastikan user adalah anggota aktif
    if (!isOwnerOrAdmin) {
      const myMemberDoc = await db
        .collection('classes')
        .doc(cleanClassId)
        .collection('members')
        .doc(user.uid)
        .get();

      if (!myMemberDoc.exists || myMemberDoc.data()?.status !== 'active') {
        return res.status(403).json({
          error: 'Akses ditolak: Anda bukan anggota aktif di kelas ini.',
        });
      }
    }

    // 3. Ambil seluruh anggota kelas
    const membersSnap = await db
      .collection('classes')
      .doc(cleanClassId)
      .collection('members')
      .get();

    // 4. Pembatasan Privasi Data Anggota:
    // - Owner kelas / Admin: display_name, account_type, status, joined_at + NIM kondisional.
    //   NIM diambil server-side (Admin SDK, bypass rules) dari users/{uid}/private/identity
    //   HANYA untuk anggota MAHASISWA (NIP dosen tidak pernah diekspos sebagai NIM).
    // - Sesama Mahasiswa: HANYA display_name (tanpa account_type, email, NIM, atau identitas privat).
    let identityMap: Record<string, string> = {};
    if (isOwnerOrAdmin) {
      const identitySnaps = await Promise.all(
        membersSnap.docs.map((doc) =>
          db.collection('users').doc(doc.id).collection('private').doc('identity').get()
        )
      );
      identitySnaps.forEach((identityDoc, index) => {
        const memberData = membersSnap.docs[index].data() || {};
        if (memberData.account_type !== 'MAHASISWA') return;
        const nim = identityDoc.data()?.nim_nip;
        if (typeof nim === 'string' && nim.trim().length > 0) {
          identityMap[membersSnap.docs[index].id] = nim.trim();
        }
      });
      console.info(
        `[class-members] NIM disclosure: caller=${user.uid} class=${cleanClassId} members=${membersSnap.size} withNim=${Object.keys(identityMap).length}`
      );
    }

    const membersList = membersSnap.docs.map((doc) => {
      const data = doc.data() || {};
      if (isOwnerOrAdmin) {
        const entry: Record<string, any> = {
          uid: doc.id,
          display_name: data.display_name || 'Anggota',
          account_type: data.account_type || 'UMUM',
          status: data.status || 'pending',
          joined_at: data.joined_at?.toDate ? data.joined_at.toDate() : data.joined_at,
        };
        if (identityMap[doc.id]) {
          entry.nim = identityMap[doc.id];
        }
        return entry;
      } else {
        return {
          uid: doc.id,
          display_name: data.display_name || 'Anggota',
        };
      }
    });

    return res.status(200).json({
      success: true,
      classId: cleanClassId,
      isOwner: isOwnerOrAdmin,
      members: membersList,
    });
  } catch (err: any) {
    console.error('Error class-members:', err);
    return res.status(500).json({ error: 'Gagal memuat daftar anggota kelas.' });
  }
}
