import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

// Safety Guard: Require emulator or explicit staging flag. FORBIDDEN in production!
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowStaging = process.env.ALLOW_STAGING_SEED === 'true';
const isProduction = process.env.NODE_ENV === 'production' || process.env.VERCEL_ENV === 'production';

if (isProduction || (!hasFirestoreEmulator && !allowStaging)) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip seeding sintetis HANYA boleh dijalankan pada Emulator');
  console.error('atau lingkungan STAGING dengan flag ALLOW_STAGING_SEED=true.');
  console.error('DILARANG KERAS dijalankan pada lingkungan produksi!');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

/**
 * Seeding Sintetis Staging / Emulator yang Merepresentasikan Kondisi Legacy
 * Data 100% fiktif untuk menguji:
 * 1. Balasan diskusi legacy (tanpa field status).
 * 2. Attempt basi > 24 jam dengan jawaban kosong.
 * 3. Kuis Draft yang memiliki attempt in_progress.
 * 4. Kuis Published dengan kunci jawaban server-only.
 * 5. Pertemuan Scheduled dengan publish_at.
 */
export async function seedStagingSynthetic() {
  console.log('🌱 ========================================================');
  console.log('📦 MENANAM DATA SINTETIS REPRESENTATIF (LEGACY CONDITIONAL TEST DATA)');
  console.log(`Target: Firestore (${process.env.FIRESTORE_EMULATOR_HOST || 'STAGING'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  const teacherUid = 'synthetic_teacher_01';
  const student1Uid = 'synthetic_student_01';
  const student2Uid = 'synthetic_student_02';
  const classId = 'synthetic_class_test';

  // 1. Kelas Sintetis
  await db.collection('classes').doc(classId).set({
    name: 'Kelas Simulasi Staging',
    code: 'STG123',
    teacher_id: teacherUid,
    status: 'Active',
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  // 2. Anggota Kelas
  await db.collection('classes').doc(classId).collection('members').doc(teacherUid).set({
    display_name: 'Dosen Simulasi',
    account_type: 'DOSEN',
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });
  await db.collection('classes').doc(classId).collection('members').doc(student1Uid).set({
    display_name: 'Mahasiswa Uji A',
    account_type: 'MAHASISWA',
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });
  await db.collection('classes').doc(classId).collection('members').doc(student2Uid).set({
    display_name: 'Mahasiswa Uji B',
    account_type: 'MAHASISWA',
    status: 'active',
    joined_at: FieldValue.serverTimestamp(),
  });

  // 3. Diskusi & Balasan Legacy (TANPA field status)
  const discId = 'synthetic_disc_legacy_01';
  await db.collection('discussions').doc(discId).set({
    class_id: classId,
    title: 'Diskusi Sintetis Staging',
    body: 'Apakah data legacy tanpa field status terbaca mulus?',
    author_id: student1Uid,
    author_display_name: 'Mahasiswa Uji A',
    status: 'ACTIVE',
    reply_count: 2,
    created_at: FieldValue.serverTimestamp(),
    last_activity_at: FieldValue.serverTimestamp(),
  });

  // Balasan 1: Normal berstatus ACTIVE
  await db.collection('discussions').doc(discId).collection('replies').doc('reply_active_synth').set({
    discussion_id: discId,
    author_id: teacherUid,
    author_display_name: 'Dosen Simulasi',
    body: 'Ini balasan normal dengan field status.',
    status: 'ACTIVE',
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  // Balasan 2: LEGACY TANPA FIELD STATUS (Meniru bug L375)
  await db.collection('discussions').doc(discId).collection('replies').doc('reply_legacy_no_status').set({
    discussion_id: discId,
    author_id: student2Uid,
    author_display_name: 'Mahasiswa Uji B',
    body: 'Ini balasan legacy zaman dulu sebelum field status diperkenalkan.',
    created_at: FieldValue.serverTimestamp(),
    updated_at: FieldValue.serverTimestamp(),
  });

  // 4. Pretest Published Lengkap dengan Kunci Jawaban
  const publishedTestId = 'synthetic_pretest_pub';
  await db.collection('pretests').doc(publishedTestId).set({
    class_id: classId,
    title: 'Pretest Algoritma Staging',
    duration: 15,
    max_attempts: 2,
    status: 'Published',
    created_at: FieldValue.serverTimestamp(),
  });
  await db.collection('pretests').doc(publishedTestId).collection('questions').doc('q1').set({
    text: 'Manakah kompleksitas binary search?',
    options: ['O(1)', 'O(log n)', 'O(n)', 'O(n^2)'],
    points: 10,
    deleted: false,
  });
  await db.collection('answer_keys').doc(publishedTestId).collection('items').doc('q1').set({
    correct_option: 1,
    points: 10,
    deleted: false,
  });

  // 5. Pretest DRAFT yang memiliki Attempt (Kondisi anomali)
  const draftTestId = 'synthetic_pretest_draft';
  await db.collection('pretests').doc(draftTestId).set({
    class_id: classId,
    title: 'Pretest Draft Anomali',
    duration: 15,
    max_attempts: 1,
    status: 'Draft',
    created_at: FieldValue.serverTimestamp(),
  });

  // 6. Attempt Basi (>24 Jam lalu) dengan jawaban kosong
  const yesterday = new Date(Date.now() - 26 * 60 * 60 * 1000);
  await db.collection('attempts').doc('synthetic_att_stale_empty').set({
    user_id: student1Uid,
    class_id: classId,
    test_id: publishedTestId,
    attempt_no: 1,
    answers: {},
    question_order: ['q1'],
    score: null,
    status: 'in_progress',
    started_at: yesterday,
    kind: 'pretest',
  });

  // 7. Pertemuan Terjadwal (Scheduled)
  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000);
  await db.collection('meetings').doc('synthetic_meet_scheduled').set({
    class_id: classId,
    number: 1,
    title: 'Pertemuan 1 Terjadwal',
    status: 'Scheduled',
    publish_at: tomorrow,
    pretest_id: publishedTestId,
    created_at: FieldValue.serverTimestamp(),
  });

  console.log('✅ Selesai menanam data sintetis representatif untuk staging.');
}

if (require.main === module) {
  seedStagingSynthetic()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Fatal seed error:', err);
      process.exit(1);
    });
}
