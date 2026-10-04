import '../../models/app_user.dart';

class DomainMap {
  // Single Source of Truth untuk pemetaan domain kampus
  // Format: domain kanonis -> AccountType
  static const Map<String, AccountType> _institutionDomains = {
    // Contoh domain institusi terdaftar
    'kampus.ac.id': AccountType.mahasiswa,
    'dosen.kampus.ac.id': AccountType.dosen,
    'farlean.edu': AccountType.mahasiswa,
    'dosen.farlean.edu': AccountType.dosen,
  };

  /// Menyelesaikan AccountType dari alamat email dengan aturan Label Boundary ketat.
  /// Contoh:
  /// - budi@kampus.ac.id -> MAHASISWA
  /// - siti@mhs.kampus.ac.id -> MAHASISWA (subdomain valid)
  /// - pak_joko@dosen.kampus.ac.id -> DOSEN
  /// - hacker@evilkampus.ac.id -> UMUM (bukan label boundary)
  /// - user@gmail.com -> UMUM
  static AccountType resolveAccountType(String? email) {
    if (email == null || !email.contains('@')) {
      return AccountType.umum;
    }

    final emailLower = email.trim().toLowerCase();
    final parts = emailLower.split('@');
    if (parts.length != 2) return AccountType.umum;

    final domain = parts[1].trim();
    if (domain.isEmpty) return AccountType.umum;

    // 1. Cek kecocokan exact subdomain spesifik dosen terlebih dahulu
    for (final entry in _institutionDomains.entries) {
      if (entry.value == AccountType.dosen) {
        if (_matchesDomainWithLabelBoundary(domain, entry.key)) {
          return AccountType.dosen;
        }
      }
    }

    // 2. Cek kecocokan mahasiswa / institusi umum
    for (final entry in _institutionDomains.entries) {
      if (entry.value == AccountType.mahasiswa) {
        if (_matchesDomainWithLabelBoundary(domain, entry.key)) {
          return AccountType.mahasiswa;
        }
      }
    }

    return AccountType.umum;
  }

  /// Memeriksa kecocokan domain dengan label boundary:
  /// domain == targetDomain ATAU domain berakhiran '.$targetDomain'
  static bool _matchesDomainWithLabelBoundary(String domain, String targetDomain) {
    if (domain == targetDomain) return true;
    if (domain.endsWith('.$targetDomain')) return true;
    return false;
  }
}
