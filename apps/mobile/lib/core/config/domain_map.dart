import '../../models/app_user.dart';

class DomainEntry {
  final String domain;
  final AccountType type;

  const DomainEntry({required this.domain, required this.type});
}

class DomainMap {
  // Single Source of Truth cerminan untuk pemetaan domain kampus (display-only)
  // Format longest-match: domain lebih spesifik/panjang berada di prioritas atas
  static const List<DomainEntry> institutionDomains = [
    DomainEntry(domain: 'dosen.farlean.edu', type: AccountType.dosen),
    DomainEntry(domain: 'farlean.edu', type: AccountType.mahasiswa),
    DomainEntry(domain: 'mhs.unesa.ac.id', type: AccountType.mahasiswa),
    DomainEntry(domain: 'unesa.ac.id', type: AccountType.dosen),
  ];

  /// Menyelesaikan AccountType dari alamat email dengan aturan Longest-Match & Label Boundary ketat.
  /// Contoh:
  /// - student@farlean.edu -> MAHASISWA
  /// - mhs@sub.farlean.edu -> MAHASISWA (subdomain valid)
  /// - teacher@dosen.farlean.edu -> DOSEN
  /// - guru@x.dosen.farlean.edu -> DOSEN (longest match mengutamakan dosen.farlean.edu)
  /// - hacker@evilfarlean.edu -> UMUM (bukan label boundary)
  /// - user@example.com -> UMUM
  static AccountType resolveAccountType(String? email) {
    if (email == null || !email.contains('@')) {
      return AccountType.umum;
    }

    final emailLower = email.trim().toLowerCase();
    final parts = emailLower.split('@');
    if (parts.length != 2) return AccountType.umum;

    final domain = parts[1].trim();
    if (domain.isEmpty) return AccountType.umum;

    // Urutkan longest-match (domain terpanjang dicek terlebih dahulu)
    final sorted = List<DomainEntry>.from(institutionDomains)
      ..sort((a, b) => b.domain.length.compareTo(a.domain.length));

    for (final entry in sorted) {
      if (_matchesDomainWithLabelBoundary(domain, entry.domain)) {
        return entry.type;
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
