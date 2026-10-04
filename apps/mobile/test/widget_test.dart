import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/app.dart';

void main() {
  testWidgets('FarleanApp bootstrap smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FarleanApp());
    await tester.pumpAndSettle();

    // Pastikan halaman login awal berhasil dirender
    expect(find.text('Masuk ke Farlean LMS'), findsOneWidget);
    expect(find.text('Email Kampus / Umum'), findsOneWidget);
  });
}

