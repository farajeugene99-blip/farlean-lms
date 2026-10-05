import { db, FieldValue } from './firebaseAdmin';
import { resolveAccountType } from './domains';

export interface BootstrapUserParams {
  uid: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  photoUrl?: string | null;
  initialRole?: 'USER' | 'GURU' | 'ADMIN';
}

export interface BootstrapUserResult {
  isNew: boolean;
  accountType: 'MAHASISWA' | 'DOSEN' | 'UMUM';
  emailVerified: boolean;
  role: string;
  message: string;
}

/**
 * Logika murni inisialisasi dokumen `users/{uid}` via Admin SDK langsung:
 * - Menentukan account_type berdasarkan status verifikasi dan domain institusi
 * - Idempoten: mempertahankan role yang sudah ada (tidak menimpa GURU/ADMIN)
 * - Dipanggil oleh endpoint HTTP `/api/bootstrap` dan script provisioning testing
 */
export async function bootstrapUser(params: BootstrapUserParams): Promise<BootstrapUserResult> {
  const { uid, email, emailVerified, name, photoUrl, initialRole = 'USER' } = params;

  const userRef = db.collection('users').doc(uid);
  const existingDoc = await userRef.get();

  // Aturan Addendum Farlean LMS:
  // - Jika email belum diverifikasi: simpan 'UMUM'
  // - Jika email sudah terverifikasi: hitung ulang dari domain (longest match)
  const calculatedAccountType = emailVerified ? resolveAccountType(email) : 'UMUM';

  if (!existingDoc.exists) {
    const newUserData = {
      uid,
      name: typeof name === 'string' && name.trim().length > 0 ? name.trim() : email.split('@')[0] || 'Pengguna',
      email,
      account_type: calculatedAccountType,
      role: initialRole,
      photo_url: typeof photoUrl === 'string' ? photoUrl : null,
      last_active: FieldValue.serverTimestamp(),
      mfa_enabled: false,
    };

    await userRef.set(newUserData);

    return {
      isNew: true,
      accountType: calculatedAccountType,
      emailVerified,
      role: initialRole,
      message: 'Profil pengguna berhasil diinisialisasi.',
    };
  } else {
    // Dokumen sudah ada: idempoten, pertahankan role yang ada (jangan menimpa GURU/ADMIN)
    const currentData = existingDoc.data() || {};
    const updates: Record<string, any> = {
      last_active: FieldValue.serverTimestamp(),
    };

    // Jika user baru saja verifikasi email, tingkatkan account_type jika sesuai domain
    if (emailVerified && currentData.account_type === 'UMUM') {
      const upgradedType = resolveAccountType(email);
      if (upgradedType !== 'UMUM') {
        updates.account_type = upgradedType;
      }
    }

    if (typeof name === 'string' && name.trim().length > 0) {
      updates.name = name.trim();
    }

    await userRef.update(updates);

    return {
      isNew: false,
      accountType: updates.account_type || currentData.account_type || 'UMUM',
      emailVerified,
      role: currentData.role || 'USER',
      message: 'Profil pengguna berhasil diperbarui.',
    };
  }
}
