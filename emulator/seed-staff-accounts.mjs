// 1. Mandatory Emulator Safety Guard (No production bypass allowed)
if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';
}
if (!process.env.FIRESTORE_EMULATOR_HOST) {
  process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
}

const isLocalAuth = process.env.FIREBASE_AUTH_EMULATOR_HOST.includes('127.0.0.1') || process.env.FIREBASE_AUTH_EMULATOR_HOST.includes('localhost');
const isLocalFirestore = process.env.FIRESTORE_EMULATOR_HOST.includes('127.0.0.1') || process.env.FIRESTORE_EMULATOR_HOST.includes('localhost');

if (!isLocalAuth || !isLocalFirestore) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Script ini HANYA boleh dijalankan pada Firebase Emulator lokal!');
  console.error('========================================================\n');
  process.exit(1);
}

import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';
import { bootstrapUser } from '../backend/lib/bootstrapUser.ts';

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const auth = getAuth();
const db = getFirestore();

// ============================================================================
// TEMPLATE DAFTAR AKUN GURU & ADMIN
// ============================================================================
// Anda dapat menambah atau mengubah daftar akun di bawah ini.
// Catatan: Gunakan domain @dosen.farlean.edu agar account_type otomatis DOSEN.
export const STAFF_ACCOUNTS = [
  {
    key: 'ADMIN UTAMA',
    email: 'admin@dosen.farlean.edu',
    name: 'Admin Farlean',
    emailVerified: true,
    initialRole: 'ADMIN',
    claims: { role: 'ADMIN' },
  },
  {
    key: 'GURU UTAMA',
    email: 'guru@dosen.farlean.edu',
    name: 'Guru Pengajar',
    emailVerified: true,
    initialRole: 'GURU',
    claims: { role: 'GURU' },
  },
  {
    key: 'GURU 2 (SEKUNDER)',
    email: 'guru2@dosen.farlean.edu',
    name: 'Guru Pengajar 2',
    emailVerified: true,
    initialRole: 'GURU',
    claims: { role: 'GURU' },
  },
];

function getPassword() {
  // 1. Dari Environment Variable jika ada
  if (process.env.FARLEAN_STAFF_PASSWORD && process.env.FARLEAN_STAFF_PASSWORD.trim().length >= 8) {
    return process.env.FARLEAN_STAFF_PASSWORD.trim();
  }
  // 2. Dari argumen CLI --password=... jika ada
  const arg = process.argv.find((a) => a.startsWith('--password='));
  if (arg) {
    const val = arg.split('=')[1]?.trim();
    if (val && val.length >= 8) return val;
  }
  // 3. Default password yang mudah diingat untuk development
  return 'FarleanStaff123!';
}

async function seedStaff() {
  console.log('========================================================');
  console.log('🌱 FARLEAN LMS — PROVISIONING AKUN GURU & ADMIN (EMULATOR)');
  console.log('========================================================');
  console.log(`Target: Auth (${process.env.FIREBASE_AUTH_EMULATOR_HOST}) | Firestore (${process.env.FIRESTORE_EMULATOR_HOST})`);

  const password = getPassword();
  console.log(`\n🔑 Password yang digunakan: ${password}\n`);

  for (const acc of STAFF_ACCOUNTS) {
    let userRecord;

    // A. Idempoten: Cek apakah user sudah terdaftar di Auth emulator
    try {
      userRecord = await auth.getUserByEmail(acc.email);
      await auth.updateUser(userRecord.uid, {
        password,
        displayName: acc.name,
        emailVerified: acc.emailVerified,
      });
      console.log(`🔄 [AUTH] Akun diperbarui: ${acc.email} (UID: ${userRecord.uid})`);
    } catch (_) {
      // User belum ada, buat baru
      userRecord = await auth.createUser({
        email: acc.email,
        password,
        displayName: acc.name,
        emailVerified: acc.emailVerified,
      });
      console.log(`✅ [AUTH] Akun baru dibuat: ${acc.email} (UID: ${userRecord.uid})`);
    }

    // B. Set Custom User Claims (Source of Truth Role untuk Security Rules)
    await auth.setCustomUserClaims(userRecord.uid, acc.claims);

    // C. Bootstrap dokumen users/{uid} secara idempoten
    const profileResult = await bootstrapUser({
      uid: userRecord.uid,
      email: acc.email,
      emailVerified: acc.emailVerified,
      name: acc.name,
      initialRole: acc.initialRole,
    });

    // Pastikan role di Firestore sinkron
    await db.collection('users').doc(userRecord.uid).set({
      role: acc.initialRole,
    }, { merge: true });

    console.log(`   └─ Profil Firestore: account_type=${profileResult.accountType}, role=${acc.initialRole}, verified=${acc.emailVerified}`);
  }

  console.log('\n========================================================');
  console.log('🎉 PROVISIONING AKUN GURU & ADMIN SELESAI!');
  console.log('========================================================');
  console.log('Daftar Akun yang Siap Digunakan:');
  for (const acc of STAFF_ACCOUNTS) {
    console.log(` • [${acc.key}]`);
    console.log(`   Email: ${acc.email}`);
    console.log(`   Password: ${password}`);
    console.log(`   Role: ${acc.initialRole}`);
  }
  console.log('--------------------------------------------------------');
  console.log('💡 Catatan Penting:');
  console.log(' • Akun ini berada di Firebase Emulator lokal.');
  console.log(' • Jika Anda merestart emulator atau emulator ter-wipe,');
  console.log('   cukup jalankan kembali: npm --prefix backend run seed:staff');
  console.log('========================================================\n');
}

seedStaff().catch((err) => {
  console.error('❌ Error saat provisioning akun staff:', err);
  process.exit(1);
});
