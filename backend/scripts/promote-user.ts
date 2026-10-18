import fs from 'fs';
import path from 'path';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { resolveAccountType } from '../lib/domains';

/**
 * Script Resmi Admin SDK Promosi, Verifikasi, & Pengaturan Role Farlean LMS
 *
 * Prinsip:
 * 1. Otomasi Verifikasi Email: Mengeset emailVerified = true langsung di Firebase Auth (anti-blokir domain farlean.edu).
 * 2. Inisialisasi Otomatis (1-Step): Jika dokumen Firestore users/{uid} belum ada, dibuatkan profil lengkap.
 * 3. Dual-write konsisten: Menulis Custom Claims (Auth) dan Mirror (Firestore users/{uid}) secara serentak.
 * 4. Memisahkan account_type (identitas) dan role (hak akses) dengan guard proteksi ADMIN.
 * 5. Guard keamanan: Menolak eksekusi produksi tanpa flag ALLOW_PRODUCTION_PROMOTION=true.
 *
 * Penggunaan:
 *   npx tsx scripts/promote-user.ts --email=guru@dosen.farlean.edu --role=GURU --accountType=DOSEN
 *   npx tsx scripts/promote-user.ts --email=admin@farlean.edu --role=ADMIN --accountType=UMUM
 *   npx tsx scripts/promote-user.ts --uid=USER_UID --role=ADMIN
 */

// Load .env.local jika tersedia dan variabel belum diset di process.env
const envPath = path.resolve(process.cwd(), '.env.local');
if (fs.existsSync(envPath)) {
  try {
    if (typeof (process as any).loadEnvFile === 'function') {
      (process as any).loadEnvFile(envPath);
    } else {
      const content = fs.readFileSync(envPath, 'utf8');
      for (const line of content.split('\n')) {
        const trimmed = line.trim();
        if (!trimmed || trimmed.startsWith('#')) continue;
        const eqIdx = trimmed.indexOf('=');
        if (eqIdx > 0) {
          const key = trimmed.slice(0, eqIdx).trim();
          let val = trimmed.slice(eqIdx + 1).trim();
          if ((val.startsWith('"') && val.endsWith('"')) || (val.startsWith("'") && val.endsWith("'"))) {
            val = val.slice(1, -1);
          }
          if (!process.env[key]) {
            process.env[key] = val;
          }
        }
      }
    }
  } catch (e) {
    // Abaikan jika env gagal dibaca
  }
}

// 1. Safety Guard
const isProdAllowed = process.env.ALLOW_PRODUCTION_PROMOTION === 'true';

if (isProdAllowed) {
  // Pastikan koneksi diarahkan ke Firebase Cloud produksi, bukan emulator lokal
  delete process.env.FIRESTORE_EMULATOR_HOST;
  delete process.env.FIREBASE_AUTH_EMULATOR_HOST;
}

const isEmulator = Boolean(
  process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST
);

if (!isEmulator && !isProdAllowed) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Script promosi role mendeteksi lingkungan non-emulator!');
  console.error('Untuk mengeksekusi pada project produksi Firebase, set environment:');
  console.error('  ALLOW_PRODUCTION_PROMOTION=true');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';
if (!getApps().length) {
  const privateKey = process.env.FIREBASE_PRIVATE_KEY
    ? process.env.FIREBASE_PRIVATE_KEY.replace(/\\n/g, '\n')
    : undefined;

  if (process.env.FIREBASE_CLIENT_EMAIL && privateKey) {
    initializeApp({
      credential: cert({
        projectId,
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
        privateKey,
      }),
    });
  } else {
    initializeApp({ projectId });
  }
}

const auth = getAuth();
const db = getFirestore();

function parseArgs() {
  const args = process.argv.slice(2);
  const params: Record<string, string> = {};
  for (const arg of args) {
    if (arg.startsWith('--')) {
      const [key, val] = arg.slice(2).split('=');
      if (key && val) params[key.trim()] = val.trim();
    }
  }
  return params;
}

async function runPromotion() {
  const params = parseArgs();
  const email = params.email;
  const uid = params.uid;
  const role = params.role?.toUpperCase();
  const requestedAccountType = params.accountType?.toUpperCase();
  const requestedName = params.name;

  if (!email && !uid) {
    console.error('❌ Argumen --email atau --uid wajib disertakan.');
    console.log('Contoh: npx tsx scripts/promote-user.ts --email=guru@dosen.farlean.edu --role=GURU --accountType=DOSEN');
    process.exit(1);
  }

  if (!role || !['USER', 'GURU', 'ADMIN'].includes(role)) {
    console.error('❌ Argumen --role tidak valid. Harus salah satu dari: USER, GURU, ADMIN.');
    process.exit(1);
  }

  if (requestedAccountType && !['MAHASISWA', 'DOSEN', 'UMUM'].includes(requestedAccountType)) {
    console.error('❌ Argumen --accountType tidak valid. Harus salah satu dari: MAHASISWA, DOSEN, UMUM.');
    process.exit(1);
  }

  console.log('========================================================');
  console.log('👑 FARLEAN LMS — PROMOSI, VERIFIKASI & INISIALISASI AKUN');
  console.log('========================================================');

  // A. Cari User di Firebase Auth
  let userRecord;
  try {
    if (uid) {
      userRecord = await auth.getUser(uid);
    } else if (email) {
      userRecord = await auth.getUserByEmail(email);
    }
  } catch (err: any) {
    console.error(`❌ Pengguna tidak ditemukan di Firebase Auth: ${err.message}`);
    process.exit(1);
  }

  if (!userRecord) {
    console.error('❌ Pengguna tidak ditemukan.');
    process.exit(1);
  }

  const targetUid = userRecord.uid;
  const targetEmail = userRecord.email || email || '';
  console.log(`Target User : ${targetEmail} (UID: ${targetUid})`);

  // B. Otomasi Verifikasi Email & Set Display Name di Firebase Auth (Solusi 1 & 3a)
  const defaultDisplayName =
    requestedName ||
    userRecord.displayName ||
    (targetEmail ? targetEmail.split('@')[0] : 'Pengguna');

  const authUpdates: Record<string, any> = {};
  if (!userRecord.emailVerified) {
    authUpdates.emailVerified = true;
  }
  if (!userRecord.displayName && defaultDisplayName) {
    authUpdates.displayName = defaultDisplayName;
  }

  if (Object.keys(authUpdates).length > 0) {
    userRecord = await auth.updateUser(targetUid, authUpdates);
    console.log(`✅ [1/3] Firebase Auth diperbarui (emailVerified: true, displayName diset):`, authUpdates);
  } else {
    console.log(`ℹ️ [1/3] Firebase Auth sudah berstatus email_verified: true.`);
  }

  // C. Dual-Write 1: Set Custom User Claims (Otoritas Utama Security Rules & Backend)
  await auth.setCustomUserClaims(targetUid, { role });
  console.log(`✅ [2/3] Custom Claims berhasil diset: { role: "${role}" }`);

  // D. Dual-Write 2: Inisialisasi Penuh atau Update Mirror Dokumen Firestore users/{uid} (Solusi 3b & 3c)
  let targetAccountType: 'MAHASISWA' | 'DOSEN' | 'UMUM';
  if (requestedAccountType) {
    targetAccountType = requestedAccountType as 'MAHASISWA' | 'DOSEN' | 'UMUM';
  } else if (role === 'ADMIN') {
    targetAccountType = 'UMUM';
  } else if (targetEmail) {
    targetAccountType = resolveAccountType(targetEmail);
  } else {
    targetAccountType = 'UMUM';
  }

  const userDocRef = db.collection('users').doc(targetUid);
  const userDoc = await userDocRef.get();
  const effectiveName = userRecord.displayName || defaultDisplayName;

  if (!userDoc.exists) {
    // Inisialisasi lengkap tanpa mengharuskan pengguna login di HP terlebih dahulu
    const initialData = {
      uid: targetUid,
      name: effectiveName,
      email: targetEmail,
      account_type: targetAccountType,
      role: role,
      photo_url: userRecord.photoURL || null,
      last_active: FieldValue.serverTimestamp(),
      mfa_enabled: false,
      created_at: FieldValue.serverTimestamp(),
      updated_at: FieldValue.serverTimestamp(),
    };
    await userDocRef.set(initialData);
    console.log(`✅ [3/3] Dokumen profil baru users/${targetUid} berhasil diinisialisasi di Firestore:`, {
      name: effectiveName,
      email: targetEmail,
      role,
      account_type: targetAccountType,
    });
  } else {
    // Dokumen sudah ada: update mirror role dan account_type
    const firestoreUpdates: Record<string, any> = {
      role,
      account_type: targetAccountType,
      updated_at: FieldValue.serverTimestamp(),
      last_active: FieldValue.serverTimestamp(),
    };
    if (!userDoc.data()?.name && effectiveName) {
      firestoreUpdates.name = effectiveName;
    }
    await userDocRef.set(firestoreUpdates, { merge: true });
    console.log(`✅ [3/3] Mirror Firestore users/${targetUid} berhasil diperbarui:`, firestoreUpdates);
  }

  console.log('\n========================================================');
  console.log('🎉 PROMOSI, VERIFIKASI & INISIALISASI BERHASIL PENUH!');
  console.log('========================================================');
  console.log(`Email         : ${targetEmail}`);
  console.log(`UID           : ${targetUid}`);
  console.log(`Nama          : ${effectiveName}`);
  console.log(`Status Email  : Terverifikasi (email_verified = true)`);
  console.log(`Custom Claim  : role = ${role}`);
  console.log(`Firestore     : role = ${role}, account_type = ${targetAccountType}`);
  console.log('--------------------------------------------------------');
  console.log('💡 Akun siap digunakan langsung:');
  console.log(' • Pengguna dapat langsung login di aplikasi mobile / web.');
  console.log(' • Jika pengguna sedang membuka sesi di aplikasi, cukup tekan');
  console.log('   "Sinkronisasi Sesi & Peran" di halaman Profil atau relogin.');
  console.log('========================================================\n');
}

runPromotion().catch((err) => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
