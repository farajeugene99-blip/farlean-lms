/// Helper terpusat untuk memformat waktu dan tanggal ke zona Waktu Indonesia Barat (WIB).
/// Menggunakan offset tetap +7 jam dari UTC (WIB tidak menerapkan daylight saving time / DST).
/// Menghindari penggunaan `toLocal()` yang menyebabkan tampilan berbeda antar perangkat/zona waktu.
class DateFormatter {
  static const Duration wibOffset = Duration(hours: 7);

  /// Mengonversi [dateTime] ke waktu WIB secara deterministik.
  static DateTime toWib(DateTime dateTime) {
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return utc.add(wibOffset);
  }

  /// Memformat [dateTime] ke format standar `DD/MM/YYYY HH:mm WIB`.
  /// Mengembalikan [fallback] jika [dateTime] bernilai null.
  static String formatWib(DateTime? dateTime, {String fallback = '-'}) {
    if (dateTime == null) return fallback;
    final wib = toWib(dateTime);
    final day = wib.day.toString().padLeft(2, '0');
    final month = wib.month.toString().padLeft(2, '0');
    final year = wib.year.toString();
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute WIB';
  }

  /// Memformat [dateTime] untuk riwayat simpan materi: `DD/MM/YYYY HH:mm • Versi {version}`.
  static String formatLastSaved(
    DateTime? dateTime,
    int version, {
    String fallback = '-',
    String versionLabel = 'Versi',
  }) {
    if (dateTime == null) return fallback;
    final wib = toWib(dateTime);
    final day = wib.day.toString().padLeft(2, '0');
    final month = wib.month.toString().padLeft(2, '0');
    final year = wib.year.toString();
    final hour = wib.hour.toString().padLeft(2, '0');
    final minute = wib.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute • $versionLabel $version';
  }
}
