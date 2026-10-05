// 1. Mandatory Emulator Safety Guard (No bypass allowed)
const hasAuthEmulator = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);

if (!hasAuthEmulator || !hasFirestoreEmulator) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Seed script HANYA boleh dijalankan pada Firebase Emulator!');
  console.error('FIREBASE_AUTH_EMULATOR_HOST dan FIRESTORE_EMULATOR_HOST wajib terdefinisi.');
  console.error('Gunakan: firebase emulators:exec --only auth,firestore "npm --prefix backend run seed:testing"');
  console.error('========================================================\n');
  process.exit(1);
}

import crypto from 'crypto';
import readline from 'readline';
import { initializeApp, getApps } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { bootstrapUser } from '../backend/lib/bootstrapUser.ts';

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const auth = getAuth();
const db = getFirestore();

const TEST_CLASS_ID = 'class_test_qa';
const TEST_CLASS_CODE = 'QATEST123';

const ACCOUNTS = [
  {
    key: 'TEST STUDENT',
    email: 'testing.student@farlean.edu',
    name: 'Test Student',
    emailVerified: true,
    initialRole: 'USER',
    claims: {},
    membershipStatus: 'active',
  },
  {
    key: 'TEST TEACHER',
    email: 'testing.teacher@dosen.farlean.edu',
    name: 'Test Teacher',
    emailVerified: true,
    initialRole: 'GURU',
    claims: { role: 'GURU' },
    membershipStatus: 'active',
  },
  {
    key: 'TEST GENERAL USER',
    email: 'testing.user@example.com',
    name: 'Test General User',
    emailVerified: true,
    initialRole: 'USER',
    claims: {},
    membershipStatus: 'pending',
  },
  {
    key: 'TEST UNVERIFIED USER',
    email: 'testing.unverified@example.com',
    name: 'Test Unverified User',
    emailVerified: false,
    initialRole: 'USER',
    claims: {},
    membershipStatus: 'pending',
  },
  {
    key: 'TEST REMOVED USER',
    email: 'testing.removed@farlean.edu',
    name: 'Test Removed Student',
    emailVerified: true,
    initialRole: 'USER',
    claims: {},
    membershipStatus: 'removed',
  },
];

async function getOrPromptPassword() {
  if (process.env.FARLEAN_TEST_PASSWORD && process.env.FARLEAN_TEST_PASSWORD.trim().length >= 8) {
    return process.env.FARLEAN_TEST_PASSWORD.trim();
  }

  if (process.stdin.isTTY && !process.env.CI) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    const answer = await new Promise((resolve) => {
      rl.question('🔑 Masukkan password untuk semua akun testing (min. 8 karakter, tekan Enter untuk acak): ', (ans) => {
        rl.close();
        resolve(ans.trim());
      });
    });
    if (answer.length >= 8) return answer;
  }

  // Generate secure random password
  const randomSuffix = crypto.randomBytes(4).toString('hex');
  return `FarleanQA_${randomSuffix}!`;
}

async function resetTestData() {
  console.log('🧹 [RESET] Membersihkan data testing lama di Emulator...');

  for (const acc of ACCOUNTS) {
    try {
      const existingUser = await auth.getUserByEmail(acc.email);
      await auth.deleteUser(existingUser.uid);
      await db.collection('users').doc(existingUser.uid).delete();
      console.log(`   - Hapus user: ${acc.email} (${existingUser.uid})`);
    } catch (_) {
      // User belum ada, abaikan
    }
  }

  try {
    const membersSnap = await db.collection('classes').doc(TEST_CLASS_ID).collection('members').get();
    for (const doc of membersSnap.docs) {
      await doc.ref.delete();
    }
    await db.collection('classes').doc(TEST_CLASS_ID).delete();
    await db.collection('class_codes').doc(TEST_CLASS_CODE).delete();
    console.log(`   - Hapus kelas & kode QA: ${TEST_CLASS_ID}`);
  } catch (_) {}

  console.log('✨ [RESET] Pembersihan selesai.\n');
}

async function seed() {
  const isReset = process.argv.includes('--reset');

  console.log('========================================================');
  console.log('🌱 FARLEAN LMS — PROVISIONING AKUN TESTING KHUSUS (EMULATOR)');
  console.log('========================================================');
  console.log(`Target: Auth (${process.env.FIREBASE_AUTH_EMULATOR_HOST}) | Firestore (${process.env.FIRESTORE_EMULATOR_HOST})`);

  if (isReset) {
    await resetTestData();
  }

  const password = await getOrPromptPassword();
  console.log(`\n🔑 Password yang digunakan: ${password}\n`);

  let teacherUid = '';

  for (const acc of ACCOUNTS) {
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
    } catch (err) {
      // User belum ada, buat baru
      userRecord = await auth.createUser({
        email: acc.email,
        password,
        displayName: acc.name,
        emailVerified: acc.emailVerified,
      });
      console.log(`✅ [AUTH] Akun dibuat: ${acc.email} (UID: ${userRecord.uid})`);
    }

    if (acc.key === 'TEST TEACHER') {
      teacherUid = userRecord.uid;
    }

    // B. Set Custom User Claims (Source of Truth Role)
    await auth.setCustomUserClaims(userRecord.uid, acc.claims);

    // C. Bootstrap dokumen users/{uid} menggunakan logika produksi langsung
    const profileResult = await bootstrapUser({
      uid: userRecord.uid,
      email: acc.email,
      emailVerified: acc.emailVerified,
      name: acc.name,
      initialRole: acc.initialRole,
    });

    console.log(`   └─ Profil Firestore: account_type=${profileResult.accountType}, role=${profileResult.role}, verified=${profileResult.emailVerified}`);
  }

  // D. Buat Kelas QA Testing
  await db.collection('classes').doc(TEST_CLASS_ID).set({
    name: 'Kelas QA — Testing Only',
    code: TEST_CLASS_CODE,
    teacher_id: teacherUid,
    updated_at: FieldValue.serverTimestamp(),
  }, { merge: true });

  await db.collection('class_codes').doc(TEST_CLASS_CODE).set({
    class_id: TEST_CLASS_ID,
  }, { merge: true });

  // E. Pasang Membership Sesuai Skenario Pengujian
  for (const acc of ACCOUNTS) {
    const userRecord = await auth.getUserByEmail(acc.email);
    const memberRef = db.collection('classes').doc(TEST_CLASS_ID).collection('members').doc(userRecord.uid);

    const docSnap = await db.collection('users').doc(userRecord.uid).get();
    const accountType = docSnap.data()?.account_type || 'UMUM';

    await memberRef.set({
      display_name: acc.name,
      account_type: accountType,
      status: acc.membershipStatus,
      joined_at: FieldValue.serverTimestamp(),
    }, { merge: true });

    console.log(`🏫 [KELAS] ${acc.key} -> status membership: '${acc.membershipStatus}' di ${TEST_CLASS_ID}`);
  }

  console.log('\n========================================================');
  console.log('🎉 PROVISIONING AKUN TESTING BERHASIL!');
  console.log('========================================================');
  console.log('Daftar Akun yang Siap Digunakan untuk Testing:');
  for (const acc of ACCOUNTS) {
    console.log(` • [${acc.key}] Email: ${acc.email} | Password: ${password}`);
  }
  console.log('Kode Kelas Uji: QATEST123');
  console.log('Catatan: Akun dan data ini HANYA berada di Firebase Emulator lokal.');
  console.log('========================================================\n');
}

seed().catch((err) => {
  console.error('❌ Error saat provisioning akun testing:', err);
  process.exit(1);
});
