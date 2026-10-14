/**
 * Single Source of Truth untuk pemetaan domain institusi di backend Farlean LMS.
 * Mengikuti aturan Longest-Match dan Label Boundary ketat:
 * domain === targetDomain || domain.endsWith('.' + targetDomain)
 * (Mencegah domain penipu seperti evilfarlean.edu)
 */
export interface DomainEntry {
  domain: string;
  type: 'MAHASISWA' | 'DOSEN';
}

// Daftar domain resmi berurutan longest-match (domain lebih spesifik/panjang berada di atas)
export const INSTITUTION_DOMAINS: DomainEntry[] = [
  { domain: 'dosen.farlean.edu', type: 'DOSEN' },
  { domain: 'farlean.edu', type: 'MAHASISWA' },
  { domain: 'mhs.unesa.ac.id', type: 'MAHASISWA' },
  { domain: 'unesa.ac.id', type: 'DOSEN' },
];

export function resolveAccountType(email?: string): 'MAHASISWA' | 'DOSEN' | 'UMUM' {
  if (!email || !email.includes('@')) return 'UMUM';
  const domain = email.toLowerCase().split('@')[1]?.trim();
  if (!domain) return 'UMUM';

  // Urutkan berdasarkan panjang domain secara menurun (longest match)
  const sortedDomains = [...INSTITUTION_DOMAINS].sort(
    (a, b) => b.domain.length - a.domain.length
  );

  for (const entry of sortedDomains) {
    if (domain === entry.domain || domain.endsWith('.' + entry.domain)) {
      return entry.type;
    }
  }

  return 'UMUM';
}
