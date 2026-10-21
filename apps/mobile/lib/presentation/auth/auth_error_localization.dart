import '../../l10n/generated/app_localizations.dart';

/// Memetakan kode error Firebase Auth ke string lokalisasi dari [AppLocalizations].
///
/// Strategi (sesuai keputusan arsitektur 2A.2.1):
/// - [AuthService.translateError] tetap statis tanpa BuildContext (tidak diubah).
/// - Layer UI mengambil kode error via [AuthProvider.authErrorCode] dan memanggil
///   [AuthErrorLocalization.fromCode] untuk mendapatkan pesan yang sesuai locale.
/// - Fallback: jika kode tidak dikenal, pakai [l10n.authErrUnknown].
/// - Pesan kustom dari throw ID (5 kasus di auth_service.dart dengan kode 'not-initialized',
///   'user-null', 'unknown') tidak memiliki kode terstruktur → jatuh ke fallback authErrUnknown.
///   Ini diterima dan terdokumentasi sebagai pembatasan fase 2A.2.1.
///
/// Kode yang dipetakan secara eksplisit:
///   user-not-found, wrong-password, invalid-credential, email-already-in-use,
///   invalid-email, weak-password, too-many-requests, network-request-failed,
///   requires-recent-login, user-disabled.
/// Catatan: `invalid-credential` menggantikan `wrong-password` dan `user-not-found`
/// di konfigurasi Firebase dengan email enumeration protection diaktifkan.
class AuthErrorLocalization {
  AuthErrorLocalization._();

  /// Mengembalikan pesan error lokalisasi untuk [code] dalam locale saat ini.
  /// [fallbackMessage] digunakan jika ada pesan teknis dari provider yang lebih
  /// deskriptif untuk kasus tidak dikenal (opsional).
  static String fromCode(
    AppLocalizations l10n,
    String? code, {
    String? fallbackMessage,
  }) {
    switch (code) {
      case 'user-not-found':
        return l10n.authErrUserNotFound;
      case 'wrong-password':
        return l10n.authErrWrongPassword;
      case 'invalid-credential':
        return l10n.authErrInvalidCredential;
      case 'account-exists-with-different-credential':
        return l10n.authErrAccountExistsDifferentCredential;
      case 'email-already-in-use':
        return l10n.authErrEmailInUse;
      case 'invalid-email':
        return l10n.authErrInvalidEmail;
      case 'weak-password':
        return l10n.authErrWeakPassword;
      case 'too-many-requests':
        return l10n.authErrTooManyRequests;
      case 'network-request-failed':
        return l10n.authErrNetworkFailed;
      case 'requires-recent-login':
        return l10n.authErrRequiresRecentLogin;
      case 'user-disabled':
        return l10n.authErrUserDisabled;
      default:
        // Kode tidak dikenal: tampilkan fallbackMessage bila tersedia,
        // atau gunakan string generik authErrUnknown.
        // Kode kustom ('not-initialized', 'user-null', 'unknown') masuk jalur ini.
        return fallbackMessage ?? l10n.authErrUnknown;
    }
  }

  /// Mengekstrak kode error dari exception Firebase Auth.
  /// Mengembalikan null jika error bukan FirebaseAuthException.
  static String? extractCode(dynamic error) {
    // Hindari import firebase_auth di sini — cek string type name
    // agar helper ini tetap dapat diuji tanpa Firebase.
    try {
      // Jika error memiliki field 'code' (FirebaseAuthException dan FirebaseException)
      final dynamic e = error;
      // ignore: avoid_dynamic_calls
      final code = e.code as String?;
      return code;
    } catch (_) {
      return null;
    }
  }
}
