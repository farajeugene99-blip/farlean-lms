import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import * as fs from 'fs';
import * as path from 'path';
import { serverTimestamp } from 'firebase/firestore';

let testEnv: RulesTestEnvironment;

async function setupDatabase() {
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  const rules = fs.readFileSync(rulesPath, 'utf8');

  testEnv = await initializeTestEnvironment({
    projectId: 'farlean-lms-test',
    firestore: {
      rules,
      host: '127.0.0.1',
      port: 8080,
    },
  });
}

async function runTests() {
  console.log('🚀 Memulai Firestore Security Rules Test Suite...');
  await setupDatabase();

  const userVerifiedUid = 'user_mhs_01';
  const userUnverifiedUid = 'user_unverified_01';
  const otherUserUid = 'user_mhs_02';
  const guruUid = 'guru_dosen_01';
  const adminUid = 'admin_super_01';
  const classId = 'class_test_01';

  // Seed data awal menggunakan context admin (bypass rules)
  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();

    // 1. Seed user profile
    await adminDb.collection('users').doc(userVerifiedUid).set({
      uid: userVerifiedUid,
      name: 'Budi Mahasiswa',
      email: 'budi@kampus.ac.id',
      account_type: 'MAHASISWA',
      role: 'USER',
      photo_url: null,
      last_active: new Date(),
      mfa_enabled: false,
    });

    await adminDb.collection('users').doc(otherUserUid).set({
      uid: otherUserUid,
      name: 'Siti Mahasiswa',
      email: 'siti@kampus.ac.id',
      account_type: 'MAHASISWA',
      role: 'USER',
      photo_url: null,
      last_active: new Date(),
      mfa_enabled: false,
    });

    // 2. Seed private identity (NIM)
    await adminDb
      .collection('users')
      .doc(userVerifiedUid)
      .collection('private')
      .doc('identity')
      .set({ nim_nip: '12345678' });

    // 3. Seed class
    await adminDb.collection('classes').doc(classId).set({
      name: 'Pemrograman Mobile Terapan',
      teacher_id: guruUid,
    });

    // 4. Seed members: userVerifiedUid = active, otherUserUid = pending, removedUser = removed
    await adminDb
      .collection('classes')
      .doc(classId)
      .collection('members')
      .doc(userVerifiedUid)
      .set({
        display_name: 'Budi',
        account_type: 'MAHASISWA',
        status: 'active',
        joined_at: new Date(),
      });

    await adminDb
      .collection('classes')
      .doc(classId)
      .collection('members')
      .doc(otherUserUid)
      .set({
        display_name: 'Siti',
        account_type: 'UMUM',
        status: 'pending',
        joined_at: new Date(),
      });

    await adminDb
      .collection('classes')
      .doc(classId)
      .collection('members')
      .doc('user_removed_01')
      .set({
        display_name: 'Removed User',
        account_type: 'UMUM',
        status: 'removed',
        joined_at: new Date(),
      });

    // 5. Seed class_codes & rate_limits
    await adminDb.collection('class_codes').doc('FARLEAN1').set({
      class_id: classId,
    });
    await adminDb.collection('rate_limits').doc(userVerifiedUid).set({
      count: 1,
    });
  });

  // Client Contexts
  const verifiedUserDb = testEnv
    .authenticatedContext(userVerifiedUid, { email_verified: true, role: 'USER' })
    .firestore();

  const unverifiedUserDb = testEnv
    .authenticatedContext(userUnverifiedUid, { email_verified: false, role: 'USER' })
    .firestore();

  const guruDb = testEnv
    .authenticatedContext(guruUid, { email_verified: true, role: 'GURU' })
    .firestore();

  const adminDb = testEnv
    .authenticatedContext(adminUid, { email_verified: true, role: 'ADMIN' })
    .firestore();

  const unauthenticatedDb = testEnv.unauthenticatedContext().firestore();

  let passed = 0;
  let failed = 0;

  async function test(name: string, fn: () => Promise<void>) {
    try {
      await fn();
      console.log(`  ✅ PASS: ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  ❌ FAIL: ${name}`);
      console.error(`     Error: ${err.message || err}`);
      failed++;
    }
  }

  // ============================================================================
  // SKENARIO 1 - 4: USERS COLLECTION ACCESS
  // ============================================================================
  await test('Skenario 1: USER terverifikasi dapat membaca profil miliknya', async () => {
    await assertSucceeds(verifiedUserDb.collection('users').doc(userVerifiedUid).get());
  });

  await test('Skenario 2: USER unverified DIBLOKIR membaca profil miliknya', async () => {
    await assertFails(unverifiedUserDb.collection('users').doc(userUnverifiedUid).get());
  });

  await test('Skenario 3: USER terverifikasi DIBLOKIR membaca profil user lain', async () => {
    await assertFails(verifiedUserDb.collection('users').doc(otherUserUid).get());
  });

  await test('Skenario 4: Client DIBLOKIR membuat dokumen users/{uid} langsung (wajib via backend)', async () => {
    await assertFails(
      verifiedUserDb.collection('users').doc('new_user').set({
        name: 'Hacker',
        role: 'USER',
      })
    );
  });

  // ============================================================================
  // SKENARIO 5 - 8: IMMUTABILITY & ROLE ESCALATION
  // ============================================================================
  await test('Skenario 5: USER DIBLOKIR mengubah role sendiri (Role Escalation Prevention)', async () => {
    await assertFails(
      verifiedUserDb.collection('users').doc(userVerifiedUid).update({
        role: 'GURU',
        last_active: serverTimestamp(),
      })
    );
  });

  await test('Skenario 6: USER DIBLOKIR mengubah account_type sendiri', async () => {
    await assertFails(
      verifiedUserDb.collection('users').doc(userVerifiedUid).update({
        account_type: 'DOSEN',
        last_active: serverTimestamp(),
      })
    );
  });

  await test('Skenario 7: USER DIBLOKIR menginjeksi field tidak sah (hanya name, photo_url, last_active)', async () => {
    await assertFails(
      verifiedUserDb.collection('users').doc(userVerifiedUid).update({
        unauthorized_field: 'injected_data',
        last_active: serverTimestamp(),
      })
    );
  });

  await test('Skenario 8: USER DAPAT memperbarui nama dan photo_url miliknya dengan serverTimestamp', async () => {
    await assertSucceeds(
      verifiedUserDb.collection('users').doc(userVerifiedUid).update({
        name: 'Budi Handoko',
        photo_url: 'https://example.com/photo.jpg',
        last_active: serverTimestamp(),
      })
    );
  });

  // ============================================================================
  // SKENARIO 9 - 11: PRIVATE IDENTITY (NIM / NIP)
  // ============================================================================
  await test('Skenario 9: USER DIBLOKIR membaca NIM/NIP milik user lain', async () => {
    await assertFails(
      verifiedUserDb
        .collection('users')
        .doc(otherUserUid)
        .collection('private')
        .doc('identity')
        .get()
    );
  });

  await test('Skenario 10: USER DAPAT membaca NIM/NIP miliknya sendiri', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('users')
        .doc(userVerifiedUid)
        .collection('private')
        .doc('identity')
        .get()
    );
  });

  await test('Skenario 11: GURU & ADMIN DAPAT membaca NIM/NIP user lain', async () => {
    await assertSucceeds(
      guruDb
        .collection('users')
        .doc(userVerifiedUid)
        .collection('private')
        .doc('identity')
        .get()
    );
    await assertSucceeds(
      adminDb
        .collection('users')
        .doc(userVerifiedUid)
        .collection('private')
        .doc('identity')
        .get()
    );
  });

  // ============================================================================
  // SKENARIO 12 - 15: CLASSES & MEMBERSHIP ENFORCEMENT
  // ============================================================================
  await test('Skenario 12: Member AKTIF dapat membaca detail kelas', async () => {
    await assertSucceeds(verifiedUserDb.collection('classes').doc(classId).get());
  });

  await test('Skenario 13: Member PENDING atau REMOVED DIBLOKIR membaca detail kelas', async () => {
    const pendingUserDb = testEnv
      .authenticatedContext(otherUserUid, { email_verified: true, role: 'USER' })
      .firestore();

    const removedUserDb = testEnv
      .authenticatedContext('user_removed_01', { email_verified: true, role: 'USER' })
      .firestore();

    await assertFails(pendingUserDb.collection('classes').doc(classId).get());
    await assertFails(removedUserDb.collection('classes').doc(classId).get());
  });

  await test('Skenario 14: Client DIBLOKIR menulis membership kelas langsung (wajib via backend)', async () => {
    await assertFails(
      verifiedUserDb
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(verifiedUserDb.app.options.authDomain || 'any')
        .set({
          display_name: 'Hacker',
          status: 'active',
        })
    );
  });

  await test('Skenario 15: Client DIBLOKIR membaca atau menulis koleksi class_codes (Deny-All)', async () => {
    await assertFails(verifiedUserDb.collection('class_codes').doc('FARLEAN1').get());
    await assertFails(
      verifiedUserDb.collection('class_codes').doc('NEWCODE').set({ class_id: classId })
    );
  });

  await test('Skenario 16: Client DIBLOKIR membaca atau menulis koleksi rate_limits (Deny-All)', async () => {
    await assertFails(verifiedUserDb.collection('rate_limits').doc(userVerifiedUid).get());
    await assertFails(
      verifiedUserDb.collection('rate_limits').doc(userVerifiedUid).set({ count: 0 })
    );
  });

  await test('Skenario 17: User tanpa otentikasi DIBLOKIR dari semua dokumen', async () => {
    await assertFails(unauthenticatedDb.collection('users').doc(userVerifiedUid).get());
    await assertFails(unauthenticatedDb.collection('classes').doc(classId).get());
  });

  // Cleanup
  await testEnv.cleanup();

  console.log(`\n========================================`);
  console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  if (failed > 0) {
    process.exit(1);
  }
}

runTests().catch((e) => {
  console.error('Fatal test error:', e);
  process.exit(1);
});
