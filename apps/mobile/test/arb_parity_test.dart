import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ARB Parity Tests (app_id.arb vs app_en.arb)', () {
    late Map<String, dynamic> idJson;
    late Map<String, dynamic> enJson;

    setUpAll(() {
      final idFile = File('lib/l10n/app_id.arb');
      final enFile = File('lib/l10n/app_en.arb');

      expect(idFile.existsSync(), isTrue, reason: 'app_id.arb harus ada');
      expect(enFile.existsSync(), isTrue, reason: 'app_en.arb harus ada');

      idJson = jsonDecode(idFile.readAsStringSync()) as Map<String, dynamic>;
      enJson = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
    });

    test('Semua key pesan di app_id.arb harus ada di app_en.arb dan sebaliknya', () {
      final idMessageKeys = idJson.keys.where((k) => !k.startsWith('@')).toSet();
      final enMessageKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

      final missingInEn = idMessageKeys.difference(enMessageKeys);
      final missingInId = enMessageKeys.difference(idMessageKeys);

      expect(missingInEn, isEmpty, reason: 'Key ada di ID tapi tidak ada di EN: $missingInEn');
      expect(missingInId, isEmpty, reason: 'Key ada di EN tapi tidak ada di ID: $missingInId');
    });

    test('Placeholder parameter bernama harus konsisten antara metadata ID dan teks EN', () {
      final idMessageKeys = idJson.keys.where((k) => !k.startsWith('@'));
      for (final key in idMessageKeys) {
        final meta = idJson['@$key'];
        final declaredPlaceholders = (meta is Map && meta['placeholders'] is Map)
            ? (meta['placeholders'] as Map).keys.cast<String>().toSet()
            : <String>{};

        final idVal = idJson[key];
        final enVal = enJson[key];

        // Pastikan setiap placeholder yang dideklarasikan ada di ID dan EN
        for (final p in declaredPlaceholders) {
          expect(
            idVal.toString().contains('{$p'),
            isTrue,
            reason: 'Placeholder "$p" dari key "$key" tidak ditemukan di teks ID ("$idVal")',
          );
          expect(
            enVal.toString().contains('{$p'),
            isTrue,
            reason: 'Placeholder "$p" dari key "$key" tidak ditemukan di teks EN ("$enVal")',
          );
        }

        // Jika tidak ada placeholder yang dideklarasikan, pastikan tidak ada token liar
        if (declaredPlaceholders.isEmpty && idVal is String && enVal is String) {
          final idHasToken = RegExp(r'\{[a-zA-Z0-9_]+\}').hasMatch(idVal);
          final enHasToken = RegExp(r'\{[a-zA-Z0-9_]+\}').hasMatch(enVal);
          expect(idHasToken, isFalse, reason: 'Key "$key" punya token di ID tapi tidak dideklarasikan di metadata');
          expect(enHasToken, isFalse, reason: 'Key "$key" punya token di EN tapi tidak dideklarasikan di metadata');
        }
      }
    });
  });
}
