import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// 1. Safety Guard: Fail-closed unless emulator or explicit production inventory flag is set
const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_INVENTORY === 'true';

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip inventarisasi produksi HANYA boleh dijalankan');
  console.error('pada Firebase Emulator atau dengan menyertakan environment variable:');
  console.error('   ALLOW_PRODUCTION_INVENTORY=true');
  console.error('Skrip ini bersifat 100% READ-ONLY dan tidak mengubah data apa pun.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

export interface InventoryReport {
  timestamp: string;
  projectId: string;
  isEmulator: boolean;
  totalAttempts: number;
  attemptsGradedWithZeroAnswers: number;
  attemptsGradedInstantUnder5s: number;
  attemptsStaleInProgressOver24h: number;
  attemptsLinkedToDraftTests: number;
  totalDiscussions: number;
  totalReplies: number;
  repliesMissingStatus: number;
  totalPretests: number;
  pretestsDraft: number;
  pretestsPublished: number;
  totalPosttests: number;
  posttestsDraft: number;
  posttestsPublished: number;
  totalMeetings: number;
  meetingsScheduled: number;
  totalMateriViews: number;
}

export async function runProductionInventory(): Promise<InventoryReport> {
  console.log('🔍 ========================================================');
  console.log('📊 MEMULAI INVENTARISASI READ-ONLY DATA PRODUKSI / STAGING');
  console.log(`Target: Firestore (${hasFirestoreEmulator ? process.env.FIRESTORE_EMULATOR_HOST : 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  const now = Date.now();

  // 1. Scan Discussions & Replies
  const discussionsSnap = await db.collection('discussions').get();
  let totalReplies = 0;
  let repliesMissingStatus = 0;

  for (const discDoc of discussionsSnap.docs) {
    const repliesSnap = await discDoc.ref.collection('replies').get();
    totalReplies += repliesSnap.size;
    for (const replyDoc of repliesSnap.docs) {
      const data = replyDoc.data();
      if (!data.status) {
        repliesMissingStatus++;
      }
    }
  }

  // 2. Scan Pretests & Posttests
  const pretestsSnap = await db.collection('pretests').get();
  let pretestsDraft = 0;
  let pretestsPublished = 0;
  const testMap: Record<string, { status: string; title: string }> = {};

  pretestsSnap.forEach((d) => {
    const st = d.data().status || 'Draft';
    if (st === 'Draft') pretestsDraft++;
    if (st === 'Published') pretestsPublished++;
    testMap[d.id] = { status: st, title: d.data().title || 'Pretest' };
  });

  const posttestsSnap = await db.collection('posttests').get();
  let posttestsDraft = 0;
  let posttestsPublished = 0;

  posttestsSnap.forEach((d) => {
    const st = d.data().status || 'Draft';
    if (st === 'Draft') posttestsDraft++;
    if (st === 'Published') posttestsPublished++;
    testMap[d.id] = { status: st, title: d.data().title || 'Posttest' };
  });

  // 3. Scan Attempts
  const attemptsSnap = await db.collection('attempts').get();
  let attemptsGradedWithZeroAnswers = 0;
  let attemptsGradedInstantUnder5s = 0;
  let attemptsStaleInProgressOver24h = 0;
  let attemptsLinkedToDraftTests = 0;

  for (const doc of attemptsSnap.docs) {
    const a = doc.data();
    const answers = a.answers || {};
    const answerCount = Object.keys(answers).length;
    const isGraded = a.status === 'graded' || a.status === 'submitted';

    const startedMs = a.started_at?.toMillis ? a.started_at.toMillis() : null;
    const submittedMs = a.submitted_at?.toMillis ? a.submitted_at.toMillis() : null;
    const durationMs = (startedMs && submittedMs) ? submittedMs - startedMs : null;

    if (isGraded && answerCount === 0) {
      attemptsGradedWithZeroAnswers++;
    }

    if (isGraded && durationMs !== null && durationMs < 5000) {
      attemptsGradedInstantUnder5s++;
    }

    if (a.status === 'in_progress' && startedMs && (now - startedMs > 24 * 60 * 60 * 1000)) {
      attemptsStaleInProgressOver24h++;
    }

    const testInfo = testMap[a.test_id];
    if (testInfo && testInfo.status === 'Draft' && a.status === 'in_progress') {
      attemptsLinkedToDraftTests++;
    }
  }

  // 4. Scan Meetings & Materi Views
  const meetingsSnap = await db.collection('meetings').get();
  let meetingsScheduled = 0;
  let totalMateriViews = 0;

  for (const mDoc of meetingsSnap.docs) {
    if (mDoc.data().status === 'Scheduled') {
      meetingsScheduled++;
    }
    const viewsSnap = await mDoc.ref.collection('materi_views').get();
    totalMateriViews += viewsSnap.size;
  }

  const report: InventoryReport = {
    timestamp: new Date().toISOString(),
    projectId,
    isEmulator: hasFirestoreEmulator,
    totalAttempts: attemptsSnap.size,
    attemptsGradedWithZeroAnswers,
    attemptsGradedInstantUnder5s,
    attemptsStaleInProgressOver24h,
    attemptsLinkedToDraftTests,
    totalDiscussions: discussionsSnap.size,
    totalReplies,
    repliesMissingStatus,
    totalPretests: pretestsSnap.size,
    pretestsDraft,
    pretestsPublished,
    totalPosttests: posttestsSnap.size,
    posttestsDraft,
    posttestsPublished,
    totalMeetings: meetingsSnap.size,
    meetingsScheduled,
    totalMateriViews,
  };

  console.log('📋 HASIL INVENTARISASI DATA:');
  console.table({
    'Total Attempts': report.totalAttempts,
    'Attempt Graded Jawaban 0': report.attemptsGradedWithZeroAnswers,
    'Attempt Graded < 5 Detik': report.attemptsGradedInstantUnder5s,
    'Attempt Basi in_progress >24 Jam': report.attemptsStaleInProgressOver24h,
    'Attempt in_progress pada Kuis Draft': report.attemptsLinkedToDraftTests,
    'Total Diskusi': report.totalDiscussions,
    'Total Balasan': report.totalReplies,
    'Balasan Tanpa Field status (Legacy)': report.repliesMissingStatus,
    'Total Pretest': report.totalPretests,
    'Pretest Draft': report.pretestsDraft,
    'Pretest Published': report.pretestsPublished,
    'Total Posttest': report.totalPosttests,
    'Posttest Draft': report.posttestsDraft,
    'Posttest Published': report.posttestsPublished,
    'Total Pertemuan': report.totalMeetings,
    'Pertemuan Terjadwal (Scheduled)': report.meetingsScheduled,
    'Total Bukti Buka Materi (materi_views)': report.totalMateriViews,
  });

  return report;
}

if (require.main === module) {
  runProductionInventory()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('Fatal inventory error:', err);
      process.exit(1);
    });
}
