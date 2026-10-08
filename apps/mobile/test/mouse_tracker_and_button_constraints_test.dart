import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/core/theme/app_theme.dart';

void main() {
  group('MouseTracker & Button Constraints Verification Tests', () {
    testWidgets('ElevatedButton and OutlinedButton in OverflowBar (AlertDialog actions) do not throw BoxConstraints infinite width exception', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AlertDialog(
                title: const Text('Test Dialog'),
                content: const Text('Test content body'),
                actions: [
                  TextButton(
                    onPressed: () {},
                    child: const Text('Batal'),
                  ),
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Kembali'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Simpan'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan tidak ada exception BoxConstraints infinite width
      expect(tester.takeException(), isNull);
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);

      // Verifikasi bahwa tombol memiliki ukuran yang terhitung (hasSize == true) dan finite
      final RenderBox elevatedBox = tester.renderObject(find.byType(ElevatedButton));
      expect(elevatedBox.hasSize, isTrue);
      expect(elevatedBox.size.width.isFinite, isTrue);
      expect(elevatedBox.size.height, equals(48.0));

      final RenderBox outlinedBox = tester.renderObject(find.byType(OutlinedButton));
      expect(outlinedBox.hasSize, isTrue);
      expect(outlinedBox.size.width.isFinite, isTrue);
      expect(outlinedBox.size.height, equals(48.0));
    });

    testWidgets('Pointer hover across buttons in dialog and unconstrained flex does NOT throw box.dart:2251 or mouse_tracker.dart:199', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: AlertDialog(
                title: const Text('Dialog Hover Test'),
                content: const SizedBox(
                  width: 440,
                  child: Text('Hover across actions test'),
                ),
                actions: [
                  OutlinedButton(
                    onPressed: () {},
                    child: const Text('Action 1'),
                  ),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Action 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Simulasikan pergerakan mouse (pointer hover) melintasi layar dan tombol
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Gerakkan mouse ke tombol OutlinedButton
      final outlinedCenter = tester.getCenter(find.text('Action 1'));
      await gesture.moveTo(outlinedCenter);
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Gerakkan mouse ke tombol ElevatedButton
      final elevatedCenter = tester.getCenter(find.text('Action 2'));
      await gesture.moveTo(elevatedCenter);
      await tester.pump();
      expect(tester.takeException(), isNull);

      // Gerakkan mouse melintasi dialog
      await gesture.moveTo(const Offset(100, 100));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ElevatedButton inside Column with CrossAxisAlignment.stretch still expands to full width as intended', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: () {},
                      child: const Text('Full Width Button'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final RenderBox btnBox = tester.renderObject(find.byType(ElevatedButton));
      expect(btnBox.hasSize, isTrue);
      // Harus tetap membentang 100% penuh mengikuti Column stretch (lebar 300)
      expect(btnBox.size.width, equals(300.0));
      expect(btnBox.size.height, equals(48.0));
    });
  });
}
