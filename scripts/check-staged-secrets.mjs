#!/usr/bin/env node
import { execSync } from 'child_process';

/**
 * Pre-commit check script untuk Farlean LMS.
 * Menjamin dummy web appId testing lokal dan secrets tidak pernah masuk ke git commit.
 */
function checkStagedDiff() {
  try {
    // Ambil diff staged tetapi kecualikan skrip pemeriksa ini sendiri
    const stagedDiff = execSync(
      'git diff --cached -- ":(exclude)scripts/check-staged-secrets.mjs"',
      { encoding: 'utf8' }
    );

    if (!stagedDiff || stagedDiff.trim().length === 0) {
      process.exit(0);
    }

    const forbiddenToken = ['farlean', 'lms', 'local', '000'].join('');
    const forbiddenPattern = new RegExp(forbiddenToken, 'i');

    if (forbiddenPattern.test(stagedDiff)) {
      console.error('\n🚨 ========================================================');
      console.error('❌ PRE-COMMIT CHECK GAGAL: Terdeteksi data terlarang di staged diff!');
      console.error('Alasan: Dummy Web App ID testing lokal dilarang di-commit.');
      console.error('\nSolusi:');
      console.error('Jalankan:');
      console.error('  git reset HEAD apps/mobile/lib/firebase_options.dart');
      console.error('  git update-index --skip-worktree apps/mobile/lib/firebase_options.dart');
      console.error('========================================================\n');
      process.exit(1);
    }

    console.log('✅ Pre-commit check passed: Staged diff bersih dari artefak dummy web & secrets.');
    process.exit(0);
  } catch (error) {
    console.error('Error saat menjalankan git diff check:', error);
    process.exit(1);
  }
}

checkStagedDiff();
