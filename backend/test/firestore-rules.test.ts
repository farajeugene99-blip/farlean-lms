import {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
  RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { setLogLevel } from '@firebase/firestore';
import * as fs from 'fs';
import * as path from 'path';
import { serverTimestamp } from 'firebase/firestore';

// Bungkam log internal gRPC Firestore
setLogLevel('silent');

process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099';

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
  console.log('🚀 Memulai Firestore Security Rules Test Suite (Phase 1 & Phase 2)...');
  await setupDatabase();

  const userVerifiedUid = 'user_mhs_01';
  const userUnverifiedUid = 'user_unverified_01';
  const otherUserUid = 'user_mhs_02';
  const removedUserUid = 'user_removed_01';
  const guruUid = 'guru_dosen_01';
  const otherGuruUid = 'guru_other_02';
  const adminUid = 'admin_super_01';
  const classId = 'class_test_01';
  const otherClassId = 'class_other_02';
  const archivedClassId = 'class_archived_03';

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

    // 3. Seed class A
    await adminDb.collection('classes').doc(classId).set({
      name: 'Pemrograman Mobile Terapan',
      code: 'MOB123',
      teacher_id: guruUid,
      status: 'Active',
    });

    // 3b. Seed class B (Dikelola oleh Guru Lain)
    await adminDb.collection('classes').doc(otherClassId).set({
      name: 'Rekayasa Perangkat Lunak',
      code: 'RPL456',
      teacher_id: otherGuruUid,
      status: 'Active',
    });

    // 3c. Seed class Archived (Milik Guru 1 tapi sudah diarsip)
    await adminDb.collection('classes').doc(archivedClassId).set({
      name: 'Kelas Arsip Lama',
      code: 'ARS789',
      teacher_id: guruUid,
      status: 'Archived',
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
      .doc(removedUserUid)
      .set({
        display_name: 'Removed User',
        account_type: 'UMUM',
        status: 'removed',
        joined_at: new Date(),
      });

    // 5. Members in otherClassId: userVerifiedUid is NOT in otherClassId

    // 6. Seed Materials (Published vs Draft)
    await adminDb.collection('materials').doc('mat_published').set({
      class_id: classId,
      title: 'Materi 1: Pengenalan Flutter',
      status: 'Published',
    });
    await adminDb.collection('materials').doc('mat_draft').set({
      class_id: classId,
      title: 'Materi 2: State Management Draft',
      status: 'Draft',
    });
    await adminDb.collection('materials').doc('mat_other_class').set({
      class_id: otherClassId,
      title: 'Materi Rahasia Kelas Lain',
      status: 'Published',
    });

    // 6b. Seed Posttests (Published vs Draft)
    await adminDb.collection('posttests').doc('posttest_published').set({
      class_id: classId,
      title: 'Post Test Evaluasi 1',
      status: 'Published',
    });
    await adminDb.collection('posttests').doc('posttest_draft').set({
      class_id: classId,
      title: 'Post Test Draft 2',
      status: 'Draft',
    });
    await adminDb
      .collection('posttests')
      .doc('posttest_published')
      .collection('questions')
      .doc('q1')
      .set({
        text: 'Manakah widget immutable?',
        options: ['StatefulWidget', 'StatelessWidget'],
        points: 10,
        tag: 'widgets',
      });

    // 7. Seed Pretests & Questions & Answer Keys
    await adminDb.collection('pretests').doc('pretest_published').set({
      class_id: classId,
      title: 'Kuis Pretest 1',
      status: 'Published',
    });
    await adminDb
      .collection('pretests')
      .doc('pretest_published')
      .collection('questions')
      .doc('q1')
      .set({
        text: 'Manakah widget immutable?',
        options: ['StatefulWidget', 'StatelessWidget'],
        points: 10,
        tag: 'widgets',
      });
    await adminDb
      .collection('answer_keys')
      .doc('pretest_published')
      .collection('items')
      .doc('q1')
      .set({
        correct_option: 1,
        points: 10,
      });

    // 8. Seed Attempts (In-Progress vs Graded)
    await adminDb.collection('attempts').doc('att_student_new').delete().catch(() => {});
    await adminDb.collection('attempts').doc('attempt_inprogress_01').set({
      user_id: userVerifiedUid,
      class_id: classId,
      test_id: 'pretest_published',
      status: 'in_progress',
      score: null,
      answers: {},
      started_at: new Date(),
    });
    await adminDb.collection('attempts').doc('attempt_graded_01').set({
      user_id: userVerifiedUid,
      class_id: classId,
      test_id: 'pretest_published',
      status: 'graded',
      score: 100,
      answers: { q1: 1 },
      started_at: new Date(),
    });

    // 9. Seed class_codes & rate_limits
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

  const pendingUserDb = testEnv
    .authenticatedContext(otherUserUid, { email_verified: true, role: 'USER' })
    .firestore();

  const removedUserDb = testEnv
    .authenticatedContext(removedUserUid, { email_verified: true, role: 'USER' })
    .firestore();

  const guruDb = testEnv
    .authenticatedContext(guruUid, { email_verified: true, role: 'GURU' })
    .firestore();

  const otherGuruDb = testEnv
    .authenticatedContext(otherGuruUid, { email_verified: true, role: 'GURU' })
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
      console.log(`  [PASS] ${name}`);
      passed++;
    } catch (err: any) {
      console.error(`  [FAIL] ${name}`);
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

  await test('Skenario 11: ADMIN DAPAT membaca NIM user lain, sedangkan GURU dari SDK client DIBLOKIR membaca identitas privat langsung', async () => {
    // Admin dapat membaca
    await assertSucceeds(
      adminDb
        .collection('users')
        .doc(userVerifiedUid)
        .collection('private')
        .doc('identity')
        .get()
    );
    // Guru dari client SDK dilarang membaca langsung (wajib via backend api/class-members yang memeriksa teacher_id kelas)
    await assertFails(
      guruDb
        .collection('users')
        .doc(userVerifiedUid)
        .collection('private')
        .doc('identity')
        .get()
    );
  });

  // ============================================================================
  // SKENARIO 12 - 17: CLASSES & MEMBERSHIP ENFORCEMENT
  // ============================================================================
  await test('Skenario 12: Member AKTIF dapat membaca detail kelas', async () => {
    await assertSucceeds(verifiedUserDb.collection('classes').doc(classId).get());
  });

  await test('Skenario 13: Member PENDING atau REMOVED DIBLOKIR membaca detail kelas', async () => {
    await assertFails(pendingUserDb.collection('classes').doc(classId).get());
    await assertFails(removedUserDb.collection('classes').doc(classId).get());
  });

  await test('Skenario 14: Client DIBLOKIR menulis membership kelas langsung (wajib via backend)', async () => {
    await assertFails(
      verifiedUserDb
        .collection('classes')
        .doc(classId)
        .collection('members')
        .doc(userVerifiedUid)
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

  // ============================================================================
  // SKENARIO 18 - 29: PHASE 2 PEMBELAJARAN, QUIL, PRETEST, ATTEMPTS
  // ============================================================================
  await test('Skenario 18: Member aktif DAPAT membaca Materi Published', async () => {
    await assertSucceeds(verifiedUserDb.collection('materials').doc('mat_published').get());
  });

  await test('Skenario 19: Member PENDING atau REMOVED DIBLOKIR membaca Materi Published', async () => {
    await assertFails(pendingUserDb.collection('materials').doc('mat_published').get());
    await assertFails(removedUserDb.collection('materials').doc('mat_published').get());
  });

  await test('Skenario 20: Member aktif DIBLOKIR membaca Materi berstatus Draft', async () => {
    await assertFails(verifiedUserDb.collection('materials').doc('mat_draft').get());
  });

  await test('Skenario 21: GURU DAPAT membuat dan mengedit Materi (Draft maupun Published)', async () => {
    await assertSucceeds(
      guruDb.collection('materials').doc('mat_new').set({
        class_id: classId,
        title: 'Materi Baru Guru',
        status: 'Draft',
      })
    );
    await assertSucceeds(
      guruDb.collection('materials').doc('mat_draft').update({
        title: 'Materi Revisi Guru',
      })
    );
  });

  await test('Skenario 22: Siswa DILARANG membaca koleksi answer_keys (100% Deny)', async () => {
    await assertFails(
      verifiedUserDb
        .collection('answer_keys')
        .doc('pretest_published')
        .collection('items')
        .doc('q1')
        .get()
    );
    await assertFails(
      verifiedUserDb
        .collection('answer_keys')
        .doc('pretest_published')
        .get()
    );
  });

  await test('Skenario 23: Siswa DAPAT membuat attempt dengan in_progress dan started_at == serverTimestamp', async () => {
    await assertSucceeds(
      verifiedUserDb.collection('attempts').doc('att_student_new').set({
        user_id: userVerifiedUid,
        class_id: classId,
        test_id: 'pretest_published',
        status: 'in_progress',
        score: null,
        started_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 24: Siswa DIBLOKIR membuat attempt jika langsung mengisi field score', async () => {
    await assertFails(
      verifiedUserDb.collection('attempts').doc('att_hacker_score').set({
        user_id: userVerifiedUid,
        class_id: classId,
        test_id: 'pretest_published',
        status: 'in_progress',
        score: 100, // ILEGAL: score harus null saat create!
        started_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 25: Siswa DAPAT mengautosave field answers selama attempt masih in_progress', async () => {
    await assertSucceeds(
      verifiedUserDb.collection('attempts').doc('attempt_inprogress_01').update({
        answers: { q1: 1 },
        last_saved_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 26: Siswa DIBLOKIR mengupdate answers setelah attempt berstatus graded/submitted', async () => {
    await assertFails(
      verifiedUserDb.collection('attempts').doc('attempt_graded_01').update({
        answers: { q1: 0 },
        last_saved_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 27: Siswa DIBLOKIR mengubah field score atau status pada attempt', async () => {
    await assertFails(
      verifiedUserDb.collection('attempts').doc('attempt_inprogress_01').update({
        score: 100, // ILEGAL
      })
    );
    await assertFails(
      verifiedUserDb.collection('attempts').doc('attempt_inprogress_01').update({
        status: 'graded', // ILEGAL: status hanya diubah oleh /api/grade
      })
    );
  });

  await test('Skenario 28: Siswa kelas A DIBLOKIR mengakses materi/pretest kelas B (Isolasi antar-kelas)', async () => {
    await assertFails(
      verifiedUserDb.collection('materials').doc('mat_other_class').get()
    );
  });

  await test('Skenario 29: Akun REMOVED DIBLOKIR membuat attempt baru di kelas tersebut', async () => {
    await assertFails(
      removedUserDb.collection('attempts').doc('att_removed_user').set({
        user_id: removedUserUid,
        class_id: classId,
        test_id: 'pretest_published',
        status: 'in_progress',
        score: null,
        started_at: serverTimestamp(),
      })
    );
  });

  // ============================================================================
  // SKENARIO 30 - 37: STRICT OWNERSHIP, CLASS IMMUTABILITY & POSTTEST RULES
  // ============================================================================
  await test('Skenario 30: Guru Non-Owner DIBLOKIR membuat materi di kelas milik Guru lain (Strict Ownership)', async () => {
    // otherGuruDb mencoba membuat materi di classId (yang dimiliki guruUid)
    await assertFails(
      otherGuruDb.collection('materials').doc('mat_cross_teacher').set({
        class_id: classId,
        title: 'Materi Ilegal Guru Lain',
        status: 'Draft',
      })
    );
  });

  await test('Skenario 31: Guru DIBLOKIR memodifikasi class_id saat update materi (Immutability class_id)', async () => {
    await assertFails(
      guruDb.collection('materials').doc('mat_published').update({
        class_id: otherClassId,
      })
    );
  });

  await test('Skenario 32: Guru DIBLOKIR membuat materi di kelas yang berstatus Archived (Write-Lock)', async () => {
    await assertFails(
      guruDb.collection('materials').doc('mat_archived_fail').set({
        class_id: archivedClassId,
        title: 'Materi di Kelas Arsip',
        status: 'Draft',
      })
    );
  });

  await test('Skenario 33: Client DIBLOKIR membuat dokumen classes/{id} langsung (Wajib via backend /api/create-class)', async () => {
    await assertFails(
      guruDb.collection('classes').doc('class_direct_client').set({
        name: 'Kelas Direct',
        code: 'DIRECT12',
        teacher_id: guruUid,
        status: 'Active',
      })
    );
  });

  await test('Skenario 34: Guru Owner DIBLOKIR mengubah code atau teacher_id pada update kelas (Immutable Code)', async () => {
    await assertFails(
      guruDb.collection('classes').doc(classId).update({
        code: 'HACKED123',
      })
    );
    await assertFails(
      guruDb.collection('classes').doc(classId).update({
        teacher_id: otherGuruUid,
      })
    );
    // Tapi boleh mengubah name atau status
    await assertSucceeds(
      guruDb.collection('classes').doc(classId).update({
        name: 'Pemrograman Mobile Terapan Revisi',
      })
    );
  });

  await test('Skenario 35: Siswa aktif DAPAT membaca Posttest Published dan DIBLOKIR membaca Posttest Draft', async () => {
    await assertSucceeds(
      verifiedUserDb.collection('posttests').doc('posttest_published').get()
    );
    await assertFails(
      verifiedUserDb.collection('posttests').doc('posttest_draft').get()
    );
  });

  await test('Skenario 36: Guru Owner DAPAT membuat Posttest dan Subkoleksi Questions di kelasnya', async () => {
    await assertSucceeds(
      guruDb.collection('posttests').doc('posttest_new').set({
        class_id: classId,
        title: 'Posttest Baru Guru',
        status: 'Draft',
      })
    );
    await assertSucceeds(
      guruDb
        .collection('posttests')
        .doc('posttest_new')
        .collection('questions')
        .doc('q_new_1')
        .set({
          text: 'Soal Baru',
          options: ['A', 'B'],
          points: 10,
        })
    );
  });

  await test('Skenario 37: Guru Non-Owner DIBLOKIR membuat Posttest di kelas Guru lain', async () => {
    await assertFails(
      otherGuruDb.collection('posttests').doc('posttest_illegal').set({
        class_id: classId,
        title: 'Posttest Ilegal',
        status: 'Draft',
      })
    );
  });

  // ============================================================================
  // SKENARIO 38 - 45: DISCUSSIONS & REPLIES SECURITY RULES
  // ============================================================================
  const discActiveId = 'disc_active_01';
  const discArchivedId = 'disc_archived_02';

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    await adminDb.collection('discussions').doc(discActiveId).set({
      class_id: classId,
      title: 'Diskusi Algoritma',
      body: 'Bagaimana membuktikan kompleksitas O(n)?',
      author_id: userVerifiedUid,
      author_display_name: 'Budi Mahasiswa',
      status: 'ACTIVE',
      reply_count: 0,
    });

    await adminDb.collection('discussions').doc(discArchivedId).set({
      class_id: classId,
      title: 'Diskusi Lama',
      body: 'Diskusi materi pertemuan lalu.',
      author_id: userVerifiedUid,
      author_display_name: 'Budi Mahasiswa',
      status: 'ARCHIVED',
      reply_count: 0,
    });
  });

  await test('Skenario 38: Client DIBLOKIR membuat dokumen discussions langsung (wajib via backend)', async () => {
    await assertFails(
      verifiedUserDb.collection('discussions').doc('disc_illegal_direct').set({
        class_id: classId,
        title: 'Diskusi Direct',
        body: 'Isi direct',
        author_id: userVerifiedUid,
        status: 'ACTIVE',
      })
    );
  });

  await test('Skenario 39: Anggota kelas aktif DAPAT membaca discussion ACTIVE di kelasnya', async () => {
    await assertSucceeds(verifiedUserDb.collection('discussions').doc(discActiveId).get());
  });

  await test('Skenario 40: Siswa kelas lain DIBLOKIR membaca discussion (Isolasi antar-kelas)', async () => {
    await assertFails(otherGuruDb.collection('discussions').doc(discActiveId).get());
  });

  await test('Skenario 41: Siswa aktif DIBLOKIR membaca discussion berstatus ARCHIVED', async () => {
    await assertFails(verifiedUserDb.collection('discussions').doc(discArchivedId).get());
  });

  await test('Skenario 42: Guru pemilik kelas DAPAT membaca discussion berstatus ARCHIVED', async () => {
    await assertSucceeds(guruDb.collection('discussions').doc(discArchivedId).get());
  });

  await test('Skenario 43: Guru pemilik kelas DAPAT mengarsipkan discussion (status -> ARCHIVED)', async () => {
    await assertSucceeds(
      guruDb.collection('discussions').doc(discActiveId).update({
        status: 'ARCHIVED',
        updated_at: new Date(),
      })
    );
  });

  await test('Skenario 44: Siswa author DAPAT mengupdate title dan body pada discussion miliknya (status ACTIVE)', async () => {
    // Kembalikan ke ACTIVE via admin
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('discussions').doc(discActiveId).update({ status: 'ACTIVE' });
    });

    await assertSucceeds(
      verifiedUserDb.collection('discussions').doc(discActiveId).update({
        title: 'Judul Revisi Siswa',
        body: 'Isi revisi pertanyaan siswa.',
        updated_at: new Date(),
      })
    );
  });

  await test('Skenario 45: Siswa author DIBLOKIR memodifikasi class_id atau author_id pada discussion miliknya', async () => {
    await assertFails(
      verifiedUserDb.collection('discussions').doc(discActiveId).update({
        author_id: 'hacker_uid',
        updated_at: new Date(),
      })
    );
  });

  // ============================================================================
  // SKENARIO 46 - 50: DISCUSSION READS RULES (STATUS BACA & PRIVASI)
  // ============================================================================
  const validReadDocId = `${userVerifiedUid}_${discActiveId}`;

  await test('Skenario 46: Siswa aktif DAPAT menulis status baca miliknya dengan serverTimestamp', async () => {
    await assertSucceeds(
      verifiedUserDb.collection('discussion_reads').doc(validReadDocId).set({
        user_id: userVerifiedUid,
        discussion_id: discActiveId,
        class_id: classId,
        last_read_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 47: Siswa DIBLOKIR menulis status baca atas nama user lain (Anti-Impersonasi)', async () => {
    await assertFails(
      verifiedUserDb.collection('discussion_reads').doc(`other_user_${discActiveId}`).set({
        user_id: 'other_user',
        discussion_id: discActiveId,
        class_id: classId,
        last_read_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 48: Siswa DIBLOKIR menulis status baca dengan waktu klien palsu (bukan serverTimestamp)', async () => {
    await assertFails(
      verifiedUserDb.collection('discussion_reads').doc(validReadDocId).set({
        user_id: userVerifiedUid,
        discussion_id: discActiveId,
        class_id: classId,
        last_read_at: new Date(2020, 1, 1),
      })
    );
  });

  await test('Skenario 49: Siswa kelas lain DIBLOKIR menulis status baca di kelas yang bukan anggotanya', async () => {
    await assertFails(
      otherGuruDb.collection('discussion_reads').doc(`${otherGuruUid}_${discActiveId}`).set({
        user_id: otherGuruUid,
        discussion_id: discActiveId,
        class_id: classId,
        last_read_at: serverTimestamp(),
      })
    );
  });

  await test('Skenario 50: Guru / Staf DIBLOKIR membaca status baca milik siswa (Privasi Riwayat Baca)', async () => {
    await assertFails(
      guruDb.collection('discussion_reads').doc(validReadDocId).get()
    );
  });

  // ============================================================================
  // SKENARIO 51 - 56: REPLIES, MATERI_VIEWS, AND PRIVACY HARDENING
  // ============================================================================
  const meetingId = 'meeting_test_01';
  const replyActiveId = 'reply_active_01';
  const replyLegacyId = 'reply_legacy_02';

  await testEnv.withSecurityRulesDisabled(async (context) => {
    const adminDb = context.firestore();
    // Seed meeting
    await adminDb.collection('meetings').doc(meetingId).set({
      class_id: classId,
      title: 'Pertemuan 1: Flutter Fundamentals',
      status: 'Published',
    });

    // Seed active reply with status: 'ACTIVE'
    await adminDb
      .collection('discussions')
      .doc(discActiveId)
      .collection('replies')
      .doc(replyActiveId)
      .set({
        discussion_id: discActiveId,
        author_id: userVerifiedUid,
        body: 'Balasan aktif baru',
        status: 'ACTIVE',
        created_at: new Date(),
      });

    // Seed legacy reply WITHOUT status field
    await adminDb
      .collection('discussions')
      .doc(discActiveId)
      .collection('replies')
      .doc(replyLegacyId)
      .set({
        discussion_id: discActiveId,
        author_id: userVerifiedUid,
        body: 'Balasan legacy lama tanpa field status',
        created_at: new Date(),
      });

    // Seed score doc in pretest_scores
    await adminDb
      .collection('classes')
      .doc(classId)
      .collection('pretest_scores')
      .doc(`pretest_published_${userVerifiedUid}`)
      .set({
        user_id: userVerifiedUid,
        test_id: 'pretest_published',
        best_score: 95,
      });
  });

  await test('Skenario 51: Siswa aktif DAPAT membaca balasan berstatus ACTIVE pada diskusi ACTIVE', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('discussions')
        .doc(discActiveId)
        .collection('replies')
        .doc(replyActiveId)
        .get()
    );
  });

  await test('Skenario 52: Siswa aktif DAPAT membaca balasan legacy tanpa field status (Anti-Breakage Legacy Replies)', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('discussions')
        .doc(discActiveId)
        .collection('replies')
        .doc(replyLegacyId)
        .get()
    );
  });

  await test('Skenario 53: Siswa aktif DAPAT membaca list/seluruh replies (termasuk legacy) di thread aktif', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('discussions')
        .doc(discActiveId)
        .collection('replies')
        .get()
    );
  });

  await test('Skenario 54: Siswa aktif DAPAT mencatat pembukaan materi di materi_views miliknya', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('meetings')
        .doc(meetingId)
        .collection('materi_views')
        .doc(userVerifiedUid)
        .set({
          materi_id: 'mat_published',
          user_id: userVerifiedUid,
          opened_at: serverTimestamp(),
        })
    );
  });

  await test('Skenario 55: Siswa DIBLOKIR menulis materi_views atas nama siswa lain (Anti-Impersonasi)', async () => {
    await assertFails(
      verifiedUserDb
        .collection('meetings')
        .doc(meetingId)
        .collection('materi_views')
        .doc(otherUserUid)
        .set({
          materi_id: 'mat_published',
          user_id: otherUserUid,
          opened_at: serverTimestamp(),
        })
    );
  });

  await test('Skenario 56: Siswa DIBLOKIR membaca pretest_scores siswa lain di kelas yang sama (Privasi Nilai)', async () => {
    // Seed second active student in classId
    const activeStudent2Uid = 'user_mhs_active_02';
    await testEnv.withSecurityRulesDisabled(async (context) => {
      await context.firestore().collection('classes').doc(classId).collection('members').doc(activeStudent2Uid).set({
        display_name: 'Dewi Mahasiswa',
        status: 'active',
      });
    });

    const dewiDb = testEnv
      .authenticatedContext(activeStudent2Uid, { email_verified: true, role: 'USER' })
      .firestore();

    await assertFails(
      dewiDb
        .collection('classes')
        .doc(classId)
        .collection('pretest_scores')
        .doc(`pretest_published_${userVerifiedUid}`)
        .get()
    );
  });

  await test('Skenario 56b: Siswa DAPAT membaca dokumen pretest_scores miliknya sendiri', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('classes')
        .doc(classId)
        .collection('pretest_scores')
        .doc(`pretest_published_${userVerifiedUid}`)
        .get()
    );
  });

  await test('Skenario 56c: Siswa DAPAT query list pretest_scores miliknya sendiri dengan filter user_id', async () => {
    await assertSucceeds(
      verifiedUserDb
        .collection('classes')
        .doc(classId)
        .collection('pretest_scores')
        .where('user_id', '==', userVerifiedUid)
        .get()
    );
  });

  await test('Skenario 56d: Guru pemilik kelas DAPAT membaca seluruh pretest_scores di kelasnya', async () => {
    await assertSucceeds(
      guruDb
        .collection('classes')
        .doc(classId)
        .collection('pretest_scores')
        .doc(`pretest_published_${userVerifiedUid}`)
        .get()
    );
  });

  await test('Skenario 56e: Guru non-owner DIBLOKIR membaca pretest_scores di kelas milik guru lain', async () => {
    await assertFails(
      otherGuruDb
        .collection('classes')
        .doc(classId)
        .collection('pretest_scores')
        .doc(`pretest_published_${userVerifiedUid}`)
        .get()
    );
  });

  await test('Skenario 57: Siswa yang BUKAN anggota kelas DIBLOKIR menulis materi_views', async () => {
    const outsiderUid = 'user_outsider_99';
    const outsiderDb = testEnv
      .authenticatedContext(outsiderUid, { email_verified: true, role: 'USER' })
      .firestore();

    await assertFails(
      outsiderDb
        .collection('meetings')
        .doc(meetingId)
        .collection('materi_views')
        .doc(outsiderUid)
        .set({
          materi_id: 'mat_published',
          user_id: outsiderUid,
          opened_at: serverTimestamp(),
        })
    );
  });

  await test('Skenario 58: Guru Owner DAPAT membuat & menjadwalkan meeting dengan status Scheduled dan publish_at', async () => {
    const scheduledMeetingId = 'meet_scheduled_01';
    const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);

    await assertSucceeds(
      guruDb.collection('meetings').doc(scheduledMeetingId).set({
        class_id: classId,
        number: 2,
        title: 'Pertemuan 2: Advanced State Management',
        status: 'Scheduled',
        publish_at: tomorrow,
      })
    );
  });

  await test('Skenario 59: Siswa aktif DAPAT membaca dokumen meeting Scheduled, sedangkan non-anggota DIBLOKIR', async () => {
    const scheduledMeetingId = 'meet_scheduled_01';

    // Siswa aktif kelas ini DAPAT membaca judul/jadwal meeting
    await assertSucceeds(
      verifiedUserDb.collection('meetings').doc(scheduledMeetingId).get()
    );

    // Pengguna non-anggota kelas (pending) DIBLOKIR
    // Catatan: GURU mana pun adalah isStaff() global sehingga tetap boleh membaca (by design)
    await assertFails(
      pendingUserDb.collection('meetings').doc(scheduledMeetingId).get()
    );
  });

  await test('Skenario 60: Siswa DIBLOKIR membuat attempt jika pretest berstatus Draft (Server-Enforced Published Gate)', async () => {
    // Seed attempt pada pretest_draft
    await assertFails(
      verifiedUserDb.collection('attempts').doc('att_illegal_draft').set({
        user_id: userVerifiedUid,
        class_id: classId,
        test_id: 'pretest_draft',
        status: 'in_progress',
        started_at: serverTimestamp(),
        kind: 'pretest',
      })
    );
  });

  await test('Skenario 61: Siswa DIBLOKIR membuat attempt jika class_id tidak cocok dengan kuis (Class Isolation)', async () => {
    await assertFails(
      verifiedUserDb.collection('attempts').doc('att_illegal_mismatched_class').set({
        user_id: userVerifiedUid,
        class_id: otherClassId, // Salah kelas!
        test_id: 'pretest_published', // Milik classId
        status: 'in_progress',
        started_at: serverTimestamp(),
        kind: 'pretest',
      })
    );
  });

  // Cleanup
  await testEnv.cleanup();

  console.log(`\n========================================`);
  console.log(`TEST SUMMARY: ${passed} PASSED, ${failed} FAILED`);
  console.log(`========================================\n`);

  process.exit(failed > 0 ? 1 : 0);
}

runTests().catch((e) => {
  console.error('Fatal test error:', e);
  process.exit(1);
});
