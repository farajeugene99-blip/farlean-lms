import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter WIB (+7) Deterministic Tests', () {
    test('Mengonversi waktu UTC ke WIB (+7) dengan benar', () {
      final utcTime = DateTime.utc(2026, 10, 11, 1, 30); // 01:30 UTC
      final formatted = DateFormatter.formatWib(utcTime);

      // 01:30 UTC + 7 jam = 08:30 WIB
      expect(formatted, equals('11/10/2026 08:30 WIB'));
    });

    test('Menangani pergantian hari saat konversi UTC ke WIB', () {
      final utcNight = DateTime.utc(2026, 10, 11, 20, 0); // 20:00 UTC
      final formatted = DateFormatter.formatWib(utcNight);

      // 20:00 UTC + 7 jam = 03:00 WIB keesokan harinya (12/10/2026)
      expect(formatted, equals('12/10/2026 03:00 WIB'));
    });

    test('formatWib mengembalikan fallback aman saat input null', () {
      expect(DateFormatter.formatWib(null), equals('-'));
      expect(DateFormatter.formatWib(null, fallback: 'waktu jadwal'), equals('waktu jadwal'));
    });

    test('formatLastSaved menyertakan nomor versi dan waktu WIB', () {
      final utcTime = DateTime.utc(2026, 10, 11, 7, 15);
      final formatted = DateFormatter.formatLastSaved(utcTime, 3);

      expect(formatted, equals('11/10/2026 14:15 • Versi 3'));
    });

    test('formatLastSaved mengembalikan fallback saat input null', () {
      expect(DateFormatter.formatLastSaved(null, 1), equals('-'));
    });
  });
}
