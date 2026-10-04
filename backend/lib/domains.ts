/**
 * Single Source of Truth untuk pemetaan domain institusi di backend
 * Mengikuti aturan Label Boundary ketat:
 * domain === instDomain || domain.endsWith('.' + instDomain)
 * (Mencegah domain penipu seperti evilkampus.ac.id)
 */
export const INSTITUTION_DOMAINS: Record<string, 'MAHASISWA' | 'DOSEN'> = {
  'kampus.ac.id': 'MAHASISWA',
  'dosen.kampus.ac.id': 'DOSEN',
  'farlean.edu': 'MAHASISWA',
  'dosen.farlean.edu': 'DOSEN',
};

export function resolveAccountType(email?: string): 'MAHASISWA' | 'DOSEN' | 'UMUM' {
  if (!email || !email.includes('@')) return 'UMUM';
  const domain = email.toLowerCase().split('@')[1];
  if (!domain) return 'UMUM';

  // 1. Cek DOSEN terlebih dahulu
  for (const [instDomain, type] of Object.entries(INSTITUTION_DOMAINS)) {
    if (type === 'DOSEN') {
      if (domain === instDomain || domain.endsWith('.' + instDomain)) {
        return 'DOSEN';
      }
    }
  }

  // 2. Cek MAHASISWA
  for (const [instDomain, type] of Object.entries(INSTITUTION_DOMAINS)) {
    if (type === 'MAHASISWA') {
      if (domain === instDomain || domain.endsWith('.' + instDomain)) {
        return 'MAHASISWA';
      }
    }
  }

  return 'UMUM';
}
