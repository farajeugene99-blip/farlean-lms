import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore } from 'firebase-admin/firestore';

/**
 * Script Resmi Admin SDK Promosi & Pengaturan Role Farlean LMS
 *
 * Prinsip:
 * 1. Dual-write konsisten: Menulis Custom Claims (Auth) dan Mirror (Firestore users/{uid}) secara serentak.
 * 2. Memisahkan account_type (identitas) dan role (hak akses).
 * 3. Guard keamanan: Menolak eksekusi produksi tanpa flag ALLOW_PRODUCTION_PROMOTION=true.
 *
 * Penggunaan:
 *   npx tsx scripts/promote-user.ts --email=guru@dosen.farlean.edu --role=GURU
 *   npx tsx scripts/promote-user.ts --email=user@gmail.com --role=GURU --accountType=UMUM
 *   npx tsx scripts/promote-user.ts --uid=USER_UID --role=ADMIN
 */

// 1. Safety Guard
const isEmulator = Boolean(
  process.env.FIRESTORE_EMULATOR_HOST || process.env.FIREBASE_AUTH_EMULATOR_HOST
);
const isProdAllowed = process.env.ALLOW_PRODUCTION_PROMOTION === 'true';

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
  initializeApp({ projectId });
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
  const accountType = params.accountType?.toUpperCase();

  if (!email && !uid) {
    console.error('❌ Argumen --email atau --uid wajib disertakan.');
    console.log('Contoh: npx tsx scripts/promote-user.ts --email=guru@dosen.farlean.edu --role=GURU');
    process.exit(1);
  }

  if (!role || !['USER', 'GURU', 'ADMIN'].includes(role)) {
    console.error('❌ Argumen --role tidak valid. Harus salah satu dari: USER, GURU, ADMIN.');
    process.exit(1);
  }

  if (accountType && !['MAHASISWA', 'DOSEN', 'UMUM'].includes(accountType)) {
    console.error('❌ Argumen --accountType tidak valid. Harus salah satu dari: MAHASISWA, DOSEN, UMUM.');
    process.exit(1);
  }

  console.log('========================================================');
  console.log('👑 FARLEAN LMS — PROMOSI & SINKRONISASI ROLE DUAL-WRITE');
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
  console.log(`Target: ${userRecord.email} (UID: ${targetUid})`);
  console.log(`Peran baru yang diberikan: ${role}`);
  if (accountType) {
    console.log(`Tipe akun baru: ${accountType}`);
  }

  // B. Dual-Write 1: Set Custom User Claims (Otoritas Utama Security Rules & Backend)
  await auth.setCustomUserClaims(targetUid, { role });
  console.log(`✅ [1/2] Custom Claims berhasil diset: { role: "${role}" }`);

  // C. Dual-Write 2: Update Mirror Dokumen Firestore users/{uid} (Display UI)
  const firestoreUpdates: Record<string, any> = {
    role,
    updated_at: new Date(),
  };
  if (accountType) {
    firestoreUpdates.account_type = accountType;
  }

  await db.collection('users').doc(targetUid).set(firestoreUpdates, { merge: true });
  console.log(`✅ [2/2] Mirror Firestore users/${targetUid} berhasil diperbarui:`, firestoreUpdates);

  console.log('\n========================================================');
  console.log('🎉 PROMOSI ROLE BERHASIL DENGAN DUAL-WRITE PENUH!');
  console.log('========================================================');
  console.log(`Email       : ${userRecord.email}`);
  console.log(`UID         : ${targetUid}`);
  console.log(`Custom Claim: role = ${role}`);
  console.log(`Firestore   : role = ${role}${accountType ? `, account_type = ${accountType}` : ''}`);
  console.log('--------------------------------------------------------');
  console.log('💡 Catatan untuk Klien:');
  console.log(' • Jika pengguna sedang membuka aplikasi, minta pengguna menekan');
  console.log('   "Perbarui Sesi" di halaman Profil atau logout & login kembali');
  console.log('   agar token client mendapatkan klaim terbaru.');
  console.log('========================================================\n');
}

runPromotion().catch((err) => {
  console.error('❌ Fatal error:', err);
  process.exit(1);
});
