import { db, auth, FieldValue } from './firebaseAdmin';
import { resolveAccountType } from './domains';

export interface BootstrapUserParams {
  uid: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  photoUrl?: string | null;
  initialRole?: 'USER' | 'GURU' | 'ADMIN';
  initialAccountType?: 'MAHASISWA' | 'DOSEN' | 'UMUM';
  completeProfile?: boolean;
  nimNip?: string | null;
  signInProvider?: string;
}

export interface BootstrapUserResult {
  isNew: boolean;
  accountType: 'MAHASISWA' | 'DOSEN' | 'UMUM';
  emailVerified: boolean;
  role: string;
  message: string;
  nim?: string | null;
  profileCompleted: boolean;
}

/**
 * Memeriksa dan mengisi otomatis nim_nip ke users/{uid}/private/identity
 * untuk mahasiswa UNESA jika email terverifikasi dan memiliki format NIM:
 * Contoh: 25050974183@mhs.unesa.ac.id -> NIM: 25050974183
 * Tidak akan menimpa nim_nip manual yang sudah ada sebelumnya.
 */
async function checkAndAutofillUnesaNim(
  userRef: FirebaseFirestore.DocumentReference,
  email: string,
  emailVerified: boolean
): Promise<string | null> {
  if (!emailVerified || !email) return null;
  const match = email.trim().match(/^(\d{8,15})@mhs\.unesa\.ac\.id$/i);
  if (!match) return null;

  const autoNim = match[1];
  const identityRef = userRef.collection('private').doc('identity');
  const identityDoc = await identityRef.get();

  if (!identityDoc.exists || !identityDoc.data()?.nim_nip) {
    await identityRef.set(
      {
        nim_nip: autoNim,
        updated_at: FieldValue.serverTimestamp(),
        auto_filled: true,
      },
      { merge: true }
    );
    return autoNim;
  }

  return identityDoc.data()?.nim_nip || null;
}

/**
 * Logika murni inisialisasi dokumen `users/{uid}` via Admin SDK langsung:
 * - Menentukan account_type berdasarkan status verifikasi dan domain institusi
 * - Idempoten: mempertahankan role yang sudah ada (tidak menimpa GURU/ADMIN)
 * - Self-healing: memperbarui account_type jika email terverifikasi sesuai domain institusi
 * - Auto-fill NIM: mengekstrak NIM dari email mhs.unesa.ac.id ke private/identity
 * - Dipanggil oleh endpoint HTTP `/api/bootstrap` dan script provisioning testing
 */
export async function bootstrapUser(params: BootstrapUserParams): Promise<BootstrapUserResult> {
  const {
    uid,
    email,
    emailVerified,
    name,
    photoUrl,
    initialRole = 'USER',
    initialAccountType,
    completeProfile,
    nimNip,
    signInProvider,
  } = params;

  const userRef = db.collection('users').doc(uid);
  const existingDoc = await userRef.get();
  const cleanNimNip = typeof nimNip === 'string' && nimNip.trim().length > 0 ? nimNip.trim() : null;

  // Aturan Addendum Farlean LMS:
  // - Jika initialAccountType ditentukan: gunakan nilai tersebut
  // - Jika initialRole === 'ADMIN': default ke 'UMUM' (Admin tidak boleh di-assign MAHASISWA walau pakai @farlean.edu)
  // - Jika email belum diverifikasi: simpan 'UMUM'
  // - Jika email sudah terverifikasi: hitung ulang dari domain (longest match)
  let calculatedAccountType: 'MAHASISWA' | 'DOSEN' | 'UMUM';
  if (initialAccountType) {
    calculatedAccountType = initialAccountType;
  } else if (initialRole === 'ADMIN') {
    calculatedAccountType = 'UMUM';
  } else if (emailVerified) {
    calculatedAccountType = resolveAccountType(email);
  } else {
    calculatedAccountType = 'UMUM';
  }

  if (!existingDoc.exists) {
    // Penentuan status kelengkapan profil pengguna baru:
    // 1. Jika completeProfile bernilai boolean eksplisit: ikuti nilai tersebut.
    // 2. Jika provider login adalah Google dan belum completeProfile: set false (wajib onboarding).
    // 3. Jika registrasi biasa Email & Password (sudah mengisi nama/data lengkap): set true.
    let isProfileCompleted: boolean;
    if (typeof completeProfile === 'boolean') {
      isProfileCompleted = completeProfile;
    } else if (signInProvider === 'google.com') {
      isProfileCompleted = false;
    } else {
      isProfileCompleted = true;
    }

    const newUserData = {
      uid,
      name: typeof name === 'string' && name.trim().length > 0 ? name.trim() : email.split('@')[0] || 'Pengguna',
      email,
      account_type: calculatedAccountType,
      role: initialRole,
      photo_url: typeof photoUrl === 'string' ? photoUrl : null,
      last_active: FieldValue.serverTimestamp(),
      mfa_enabled: false,
      profile_completed: isProfileCompleted,
    };

    const batch = db.batch();
    batch.set(userRef, newUserData);

    const identityRef = userRef.collection('private').doc('identity');
    if (cleanNimNip) {
      batch.set(
        identityRef,
        {
          nim_nip: cleanNimNip,
          updated_at: FieldValue.serverTimestamp(),
          auto_filled: false,
        },
        { merge: true }
      );
    }
    await batch.commit();

    try {
      await auth.setCustomUserClaims(uid, { role: initialRole });
    } catch (_) {}

    let savedNim = cleanNimNip;
    if (!savedNim) {
      savedNim = await checkAndAutofillUnesaNim(userRef, email, emailVerified);
    }

    return {
      isNew: true,
      accountType: calculatedAccountType,
      emailVerified,
      role: initialRole,
      nim: savedNim,
      profileCompleted: isProfileCompleted,
      message: 'Profil pengguna berhasil diinisialisasi.',
    };
  } else {
    // Dokumen sudah ada: idempoten, pertahankan role yang ada (jangan menimpa GURU/ADMIN)
    const currentData = existingDoc.data() || {};
    const updates: Record<string, any> = {
      last_active: FieldValue.serverTimestamp(),
    };

    let finalAccountType: 'MAHASISWA' | 'DOSEN' | 'UMUM' = currentData.account_type || 'UMUM';

    // Self-healing: Jika email terverifikasi dan akun masih UMUM atau belum sesuai domain institusi resmi
    // PENTING: Role ADMIN dikecualikan dari auto-override agar admin@farlean.edu tidak tertimpa menjadi MAHASISWA
    if (emailVerified && currentData.role !== 'ADMIN') {
      const resolved = resolveAccountType(email);
      if (resolved !== 'UMUM' && currentData.account_type !== resolved) {
        if (currentData.account_type === 'UMUM' || !currentData.account_type) {
          updates.account_type = resolved;
          finalAccountType = resolved;
        }
      }
    }

    if (typeof name === 'string' && name.trim().length > 0) {
      updates.name = name.trim();
    }

    // Pembaruan profile_completed secara aman & idempoten:
    // - Jika completeProfile diberikan: update ke nilai tersebut
    // - Jika dokumen existing sudah punya nilai: pertahankan nilai tersebut
    // - Default untuk akun legacy (sebelum fitur onboarding): anggap true agar tidak terkunci
    let finalProfileCompleted: boolean;
    if (typeof completeProfile === 'boolean') {
      updates.profile_completed = completeProfile;
      finalProfileCompleted = completeProfile;
    } else if (currentData.profile_completed !== undefined) {
      finalProfileCompleted = Boolean(currentData.profile_completed);
    } else {
      finalProfileCompleted = true;
    }

    const batch = db.batch();
    batch.update(userRef, updates);

    const identityRef = userRef.collection('private').doc('identity');
    if (cleanNimNip) {
      batch.set(
        identityRef,
        {
          nim_nip: cleanNimNip,
          updated_at: FieldValue.serverTimestamp(),
          auto_filled: false,
        },
        { merge: true }
      );
    }
    await batch.commit();

    try {
      await auth.setCustomUserClaims(uid, { role: currentData.role || 'USER' });
    } catch (_) {}

    let savedNim = cleanNimNip;
    if (!savedNim) {
      savedNim = await checkAndAutofillUnesaNim(userRef, email, emailVerified);
    }

    return {
      isNew: false,
      accountType: finalAccountType,
      emailVerified,
      role: currentData.role || 'USER',
      nim: savedNim,
      profileCompleted: finalProfileCompleted,
      message: updates.account_type
        ? 'Tipe akun berhasil diperbarui sesuai domain institusi.'
        : 'Profil pengguna berhasil diperbarui.',
    };
  }
}
