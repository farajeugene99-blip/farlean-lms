import '../../l10n/generated/app_localizations.dart';
import '../../services/auth_provider.dart';

/// Helper presentasi untuk memetakan [ProfileErrorReason] ke pesan lokalisasi.
///
/// Memastikan seluruh varian enum [ProfileErrorReason.values] tertangani secara konsisten
/// tanpa mengubah model atau kontrak [AuthProvider].
class DashboardProfileErrorLocalization {
  DashboardProfileErrorLocalization._();

  /// Mengembalikan pesan error sesuai [ProfileErrorReason] pada [provider].
  static String message(AuthProvider provider, AppLocalizations l10n) {
    return messageForReason(
      provider.profileErrorReason,
      l10n,
      customError: provider.profileErrorMessage,
    );
  }

  /// Memetakan [reason] langsung ke pesan terlokalisasi.
  /// Menjamin seluruh varian [ProfileErrorReason.values] teruji dan memiliki fallback aman.
  static String messageForReason(
    ProfileErrorReason reason,
    AppLocalizations l10n, {
    String? customError,
  }) {
    switch (reason) {
      case ProfileErrorReason.network:
        return l10n.dashboardProfileErrorNetwork;
      case ProfileErrorReason.notFound:
        return l10n.dashboardProfileErrorNotFound;
      case ProfileErrorReason.permissionDenied:
        return l10n.dashboardProfileErrorPermission;
      case ProfileErrorReason.unknown:
      case ProfileErrorReason.none:
        return customError ?? l10n.dashboardProfileErrorDefault;
    }
  }
}
