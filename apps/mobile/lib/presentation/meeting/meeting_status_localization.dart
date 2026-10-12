import '../../l10n/generated/app_localizations.dart';
import '../../models/content_status.dart';

/// Helper presentasi untuk melokalisasi label [ContentStatus] pada modul Meeting.
///
/// Memisahkan label UI dari nilai domain enum/Firestore.
/// Nilai domain mentah (misalnya 'Draft', 'Scheduled') tidak berubah di database.
///
/// Jika status tidak dikenal atau null, helper menampilkan nilai mentah (fallback)
/// agar masalah data tetap terdeteksi oleh pengembang dan pengguna.
class MeetingStatusLocalization {
  MeetingStatusLocalization._();

  /// Mengembalikan label status lokalisasi sesuai locale aktif.
  static String label(ContentStatus? status, AppLocalizations l10n) {
    if (status == null) return '-';
    switch (status) {
      case ContentStatus.draft:
        return l10n.meetingStatusDraft;
      case ContentStatus.scheduled:
        return l10n.meetingStatusScheduled;
      case ContentStatus.published:
        return l10n.meetingStatusPublished;
      case ContentStatus.archived:
        return l10n.meetingStatusArchived;
    }
  }

  /// Mengembalikan label status dalam huruf besar (misalnya untuk header badge sheet).
  static String labelUpperCase(ContentStatus? status, AppLocalizations l10n) {
    return label(status, l10n).toUpperCase();
  }

  /// Fallback aman untuk memetakan string status mentah yang mungkin berasal dari
  /// respon backend/Firestore ke label lokalisasi.
  /// Jika string tidak cocok dengan status manapun, mengembalikan [rawStatus] apa adanya.
  static String fromRawString(String? rawStatus, AppLocalizations l10n) {
    if (rawStatus == null || rawStatus.isEmpty) return '-';
    final parsed = ContentStatus.fromString(rawStatus);
    // Jika fromString fallback ke draft tapi string aslinya bukan 'draft',
    // tampilkan string aslinya agar anomali data tetap terlihat.
    if (parsed == ContentStatus.draft && rawStatus.toLowerCase() != 'draft') {
      return rawStatus;
    }
    return label(parsed, l10n);
  }
}
