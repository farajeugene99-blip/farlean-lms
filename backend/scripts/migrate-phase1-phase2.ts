import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

// 1. Safety Guard: Require emulator or explicit production override
const hasAuthEmulator = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_MIGRATION === 'true';

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip migrasi HANYA boleh dijalankan pada Firebase Emulator');
  console.error('atau dengan environment variable ALLOW_PRODUCTION_MIGRATION=true.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

export async function runMigration() {
  console.log('🔄 ========================================================');
  console.log('📦 MEMULAI IDEMPOTENT MIGRATION SCRIPT (PHASE 1 & 2 GAP CLOSURE)');
  console.log(`Target: Firestore (${process.env.FIRESTORE_EMULATOR_HOST || 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  let classesMigrated = 0;
  let videosMigrated = 0;
  let manualBooksMigrated = 0;
  let attemptsMigrated = 0;
  let meetingsMigrated = 0;

  // A. Backfill classes: status ('Active'), description (''), teacher_id, timestamps
  const classesSnap = await db.collection('classes').get();
  for (const doc of classesSnap.docs) {
    const data = doc.data();
    const updates: Record<string, any> = {};

    if (!data.status) updates.status = 'Active';
    if (data.description === undefined) updates.description = '';
    if (!data.teacher_id) updates.teacher_id = '';
    if (!data.created_at) updates.created_at = FieldValue.serverTimestamp();
    if (!data.updated_at) updates.updated_at = FieldValue.serverTimestamp();

    if (Object.keys(updates).length > 0) {
      await doc.ref.set(updates, { merge: true });
      classesMigrated++;
    }
  }
  console.log(`✅ Classes checked: ${classesSnap.size}, backfilled: ${classesMigrated}`);

  // B. Backfill videos: status ('Published')
  const videosSnap = await db.collection('videos').get();
  for (const doc of videosSnap.docs) {
    const data = doc.data();
    if (!data.status) {
      await doc.ref.set({ status: 'Published' }, { merge: true });
      videosMigrated++;
    }
  }
  console.log(`✅ Videos checked: ${videosSnap.size}, backfilled: ${videosMigrated}`);

  // C. Backfill manual_books: status ('Published')
  const booksSnap = await db.collection('manual_books').get();
  for (const doc of booksSnap.docs) {
    const data = doc.data();
    if (!data.status) {
      await doc.ref.set({ status: 'Published' }, { merge: true });
      manualBooksMigrated++;
    }
  }
  console.log(`✅ Manual Books checked: ${booksSnap.size}, backfilled: ${manualBooksMigrated}`);

  // D. Backfill attempts: kind ('pretest')
  const attemptsSnap = await db.collection('attempts').get();
  for (const doc of attemptsSnap.docs) {
    const data = doc.data();
    if (!data.kind) {
      await doc.ref.set({ kind: 'pretest' }, { merge: true });
      attemptsMigrated++;
    }
  }
  console.log(`✅ Attempts checked: ${attemptsSnap.size}, backfilled: ${attemptsMigrated}`);

  // E. Backfill meetings: ensure status ('Draft' default if missing)
  const meetingsSnap = await db.collection('meetings').get();
  for (const doc of meetingsSnap.docs) {
    const data = doc.data();
    if (!data.status) {
      await doc.ref.set({ status: 'Draft' }, { merge: true });
      meetingsMigrated++;
    }
  }
  console.log(`✅ Meetings checked: ${meetingsSnap.size}, backfilled: ${meetingsMigrated}`);

  console.log('\n✨ Migrasi data idempoten selesai dengan sukses!\n');
}

// Auto-run if executed directly
if (require.main === module) {
  runMigration().catch((err) => {
    console.error('❌ Error migrasi:', err);
    process.exit(1);
  });
}
