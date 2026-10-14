import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Skrip Dump Koleksi Kritis (Hemat Kuota Spark)
 *
 * Mengambil data attempts, discussions, dan replies untuk cadangan darurat lokal
 * sebelum operasi migrasi/backfill.
 *
 * Guard Keamanan:
 * - Menjalankan count() terlebih dahulu untuk memperingatkan jika kuota baca harian berisiko.
 * - Menyimpan ke folder aman lokal (diabaikan git).
 */

const hasFirestoreEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
const allowProduction = process.env.ALLOW_PRODUCTION_DUMP === 'true';

if (!hasFirestoreEmulator && !allowProduction) {
  console.error('\n🚨 ========================================================');
  console.error('❌ FATAL: Skrip dump kritis HANYA boleh dijalankan pada Firebase Emulator');
  console.error('atau dengan environment variable ALLOW_PRODUCTION_DUMP=true.');
  console.error('========================================================\n');
  process.exit(1);
}

const projectId = process.env.FIREBASE_PROJECT_ID || 'farlean-lms';

if (!getApps().length) {
  initializeApp({ projectId });
}

const db = getFirestore();

export async function runCriticalDump() {
  console.log('🔄 ========================================================');
  console.log('📦 MEMULAI READ-ONLY DUMP KOLEKSI KRITIS');
  console.log(`Target: Firestore (${hasFirestoreEmulator ? process.env.FIRESTORE_EMULATOR_HOST : 'PRODUCTION'}) | Project: ${projectId}`);
  console.log('========================================================\n');

  // 1. Cek jumlah dokumen dengan count() murah (1 operasi per agregasi)
  const attemptsCount = (await db.collection('attempts').count().get()).data().count;
  const discussionsCount = (await db.collection('discussions').count().get()).data().count;

  console.log(`📊 Estimasi Dokumen: attempts=${attemptsCount}, discussions=${discussionsCount}`);
  const totalEstimated = attemptsCount + discussionsCount;

  if (totalEstimated > 20000 && !hasFirestoreEmulator) {
    console.warn(`⚠️ PERINGATAN: Total dokumen (${totalEstimated}) mendekati batas baca Spark harian (50.000).`);
  }

  const dumpDir = path.resolve(__dirname, '../.dump');
  if (!fs.existsSync(dumpDir)) {
    fs.mkdirSync(dumpDir, { recursive: true });
  }

  // Dump attempts
  console.log('📥 Mengunduh koleksi attempts...');
  const attemptsSnap = await db.collection('attempts').get();
  const attemptsData = attemptsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  fs.writeFileSync(path.join(dumpDir, 'attempts-backup.json'), JSON.stringify(attemptsData, null, 2));

  // Dump discussions
  console.log('📥 Mengunduh koleksi discussions...');
  const discussionsSnap = await db.collection('discussions').get();
  const discussionsData = discussionsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
  fs.writeFileSync(path.join(dumpDir, 'discussions-backup.json'), JSON.stringify(discussionsData, null, 2));

  console.log(`\n✅ DUMP SELESAI! Data tersimpan di folder aman: ${dumpDir}`);
  console.log(`Total attempts di-dump   : ${attemptsData.length}`);
  console.log(`Total discussions di-dump: ${discussionsData.length}`);
}

if (require.main === module) {
  runCriticalDump().catch((e) => {
    console.error('Fatal dump execution error:', e);
    process.exit(1);
  });
}
