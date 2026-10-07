import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/video_item.dart';

void main() {
  group('VideoProvider Dropdown Layout Tests', () {
    testWidgets('DropdownButtonFormField renders without RenderFlex overflow in narrow width (202px)', (tester) async {
      VideoProvider selectedProvider = VideoProvider.youtube;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 202.0, // Batas sempit sesuai temuan error log
                child: DropdownButtonFormField<VideoProvider>(
                  isExpanded: true,
                  initialValue: selectedProvider,
                  decoration: const InputDecoration(
                    labelText: 'Penyedia Video',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: VideoProvider.youtube,
                      child: Text(
                        'YouTube Video',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    DropdownMenuItem(
                      value: VideoProvider.cloudinary,
                      child: Text(
                        'Cloudinary (MP4/URL)',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                  onChanged: (val) {
                    if (val != null) selectedProvider = val;
                  },
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tidak boleh ada exception overflow
      expect(tester.takeException(), isNull);
      expect(find.byWidgetPredicate((Widget w) => w is DropdownButtonFormField), findsOneWidget);
      expect(find.text('YouTube Video'), findsOneWidget);

      // Buka dropdown
      await tester.tap(find.byWidgetPredicate((Widget w) => w is DropdownButtonFormField));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Cloudinary (MP4/URL)'), findsWidgets);

      // Pilih Cloudinary
      await tester.tap(find.text('Cloudinary (MP4/URL)').last);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(selectedProvider, equals(VideoProvider.cloudinary));
    });
  });
}
