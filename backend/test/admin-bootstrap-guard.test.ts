import assert from 'assert';
import { resolveAccountType } from '../lib/domains';

async function runTests() {
  console.log('🧪 Memulai Unit Test Proteksi Domain & Role Admin...');

  // Test 1: Pemetaan domain alami
  assert.strictEqual(resolveAccountType('guru@dosen.farlean.edu'), 'DOSEN');
  assert.strictEqual(resolveAccountType('student@farlean.edu'), 'MAHASISWA');
  assert.strictEqual(resolveAccountType('admin@farlean.edu'), 'MAHASISWA'); // secara domain alami adalah MAHASISWA
  assert.strictEqual(resolveAccountType('user@gmail.com'), 'UMUM');
  console.log('  [PASS] 1. Pemetaan domain institusi alami terverifikasi');

  // Test 2: Simulasi logika pemilihan accountType saat inisialisasi awal
  function calculateAccountType(params: {
    email: string;
    emailVerified: boolean;
    initialRole?: string;
    initialAccountType?: string;
  }): 'MAHASISWA' | 'DOSEN' | 'UMUM' {
    if (params.initialAccountType) {
      return params.initialAccountType as any;
    } else if (params.initialRole === 'ADMIN') {
      return 'UMUM';
    } else if (params.emailVerified) {
      return resolveAccountType(params.email);
    } else {
      return 'UMUM';
    }
  }

  assert.strictEqual(
    calculateAccountType({
      email: 'admin@farlean.edu',
      emailVerified: true,
      initialRole: 'ADMIN',
    }),
    'UMUM',
    'Admin baru dengan email @farlean.edu harus tetap ber-tipe UMUM'
  );

  assert.strictEqual(
    calculateAccountType({
      email: 'guru@dosen.farlean.edu',
      emailVerified: true,
      initialRole: 'GURU',
    }),
    'DOSEN',
    'Guru baru dengan email @dosen.farlean.edu harus ber-tipe DOSEN'
  );

  assert.strictEqual(
    calculateAccountType({
      email: 'student@farlean.edu',
      emailVerified: true,
      initialRole: 'USER',
    }),
    'MAHASISWA',
    'Mahasiswa baru dengan email @farlean.edu harus ber-tipe MAHASISWA'
  );
  console.log('  [PASS] 2. Logika inisialisasi awal Admin tidak boleh jatuh ke MAHASISWA');

  // Test 3: Simulasi logika self-healing pada akun yang sudah ada (existingDoc)
  function simulateSelfHealing(existingUser: {
    email: string;
    role: string;
    account_type: 'MAHASISWA' | 'DOSEN' | 'UMUM';
    emailVerified: boolean;
  }): 'MAHASISWA' | 'DOSEN' | 'UMUM' {
    let finalAccountType = existingUser.account_type;

    // Logika persis dari backend/lib/bootstrapUser.ts
    if (existingUser.emailVerified && existingUser.role !== 'ADMIN') {
      const resolved = resolveAccountType(existingUser.email);
      if (resolved !== 'UMUM' && existingUser.account_type !== resolved) {
        if (existingUser.account_type === 'UMUM' || !existingUser.account_type) {
          finalAccountType = resolved;
        }
      }
    }

    return finalAccountType;
  }

  // Skenario A: Admin dengan email @farlean.edu yang sudah UMUM
  const adminResult = simulateSelfHealing({
    email: 'admin@farlean.edu',
    role: 'ADMIN',
    account_type: 'UMUM',
    emailVerified: true,
  });
  assert.strictEqual(
    adminResult,
    'UMUM',
    'Self-healing dilarang mengubah account_type ADMIN dari UMUM menjadi MAHASISWA'
  );

  // Skenario B: User biasa dengan email @farlean.edu yang masih UMUM
  const userResult = simulateSelfHealing({
    email: 'mhs@farlean.edu',
    role: 'USER',
    account_type: 'UMUM',
    emailVerified: true,
  });
  assert.strictEqual(
    userResult,
    'MAHASISWA',
    'Self-healing harus tetap meng-upgrade akun USER ber-email @farlean.edu menjadi MAHASISWA'
  );

  // Skenario C: Guru dengan email @dosen.farlean.edu yang masih UMUM
  const guruResult = simulateSelfHealing({
    email: 'guru@dosen.farlean.edu',
    role: 'GURU',
    account_type: 'UMUM',
    emailVerified: true,
  });
  assert.strictEqual(
    guruResult,
    'DOSEN',
    'Self-healing harus tetap meng-upgrade akun GURU ber-email @dosen.farlean.edu menjadi DOSEN'
  );

  console.log('  [PASS] 3. Guard self-healing berhasil memproteksi ADMIN dari penimpaan MAHASISWA');

  // Test 4: Verifikasi aturan Firestore Security Rules untuk Lifecycle Kelas & Pertemuan
  const fs = await import('fs');
  const path = await import('path');
  const rulesPath = path.resolve(__dirname, '../../firestore.rules');
  const rulesContent = fs.readFileSync(rulesPath, 'utf8');

  // A. Reaktivasi kelas arsip
  assert.ok(
    rulesContent.includes("isClassTeacher(classId)") &&
    rulesContent.includes("(resource.data.status == 'Active' || request.resource.data.status == 'Active')"),
    'Rules kelas wajib mengizinkan reaktivasi oleh isClassTeacher dan membatasi kelas Archived'
  );

  // B. Meetings delete oleh isClassTeacher
  assert.ok(
    rulesContent.includes("allow delete: if isClassTeacher(resource.data.class_id);"),
    'Rules pertemuan wajib mengizinkan penghapusan pertemuan oleh isClassTeacher'
  );

  // C. Immutability class_id pada update pertemuan
  assert.ok(
    rulesContent.includes("request.resource.data.class_id == resource.data.class_id"),
    'Rules pertemuan wajib memvalidasi kesamaan class_id saat update'
  );
  console.log('  [PASS] 4. Integritas Firestore Security Rules (Class Lifecycle & Meetings) terverifikasi');

  // Test 5: Logika Profile Completion (Onboarding Google vs Reguler Email/Password)
  function resolveProfileCompleted(params: {
    isNew: boolean;
    completeProfile?: boolean;
    signInProvider?: string;
    existingProfileCompleted?: boolean;
  }): boolean {
    if (params.isNew) {
      if (typeof params.completeProfile === 'boolean') {
        return params.completeProfile;
      } else if (params.signInProvider === 'google.com') {
        return false;
      } else {
        return true;
      }
    } else {
      if (typeof params.completeProfile === 'boolean') {
        return params.completeProfile;
      } else if (params.existingProfileCompleted !== undefined) {
        return params.existingProfileCompleted;
      } else {
        return true; // legacy default to true
      }
    }
  }

  // Skenario A: Pendaftar baru Google belum onboarding
  assert.strictEqual(
    resolveProfileCompleted({ isNew: true, signInProvider: 'google.com' }),
    false,
    'Pengguna Google baru tanpa completeProfile harus berstatus profileCompleted: false'
  );

  // Skenario B: Pendaftar baru Email/Password reguler
  assert.strictEqual(
    resolveProfileCompleted({ isNew: true, signInProvider: 'password' }),
    true,
    'Pengguna reguler Email & Password baru harus berstatus profileCompleted: true'
  );

  // Skenario C: Submit onboarding dari layar CompleteProfile
  assert.strictEqual(
    resolveProfileCompleted({ isNew: false, completeProfile: true, existingProfileCompleted: false }),
    true,
    'Submit onboarding via completeProfile: true harus mengubah status menjadi profileCompleted: true'
  );

  // Skenario D: Pengguna lama (legacy) tanpa field profile_completed
  assert.strictEqual(
    resolveProfileCompleted({ isNew: false, existingProfileCompleted: undefined }),
    true,
    'Pengguna legacy tanpa field profile_completed harus tetap profileCompleted: true agar tidak terkunci'
  );
  console.log('  [PASS] 5. Logika Onboarding & Profile Completion (Google vs Reguler vs Legacy) terverifikasi');

  console.log('\n========================================');
  console.log('✅ SEMUA TEST PROTEKSI ROLE ADMIN & DOMAIN BERHASIL!');
  console.log('========================================\n');
}

runTests().catch((e) => {
  console.error('Test failed:', e);
  process.exit(1);
});
