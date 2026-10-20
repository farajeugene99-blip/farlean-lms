import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class _LineSegment {
  final String text;
  final Map<String, dynamic> attributes;
  const _LineSegment(this.text, this.attributes);
}

class DeltaPdfConverter {
  /// Mengonversi Delta JSON dari flutter_quill menjadi berkas PDF Uint8List
  static Future<Uint8List> convertToPdf({
    required String title,
    String? subtitle,
    required dynamic deltaContent,
    Future<Uint8List?> Function(String url)? imageLoader,
    pw.Font? customBaseFont,
    pw.Font? customBoldFont,
    pw.Font? customItalicFont,
  }) async {
    final pdf = pw.Document();

    // 1. Pemuatan Font Aman dengan Fallback (Guardrail 3)
    pw.Font baseFont;
    pw.Font boldFont;
    pw.Font italicFont;
    bool isFallbackFont = false;

    if (customBaseFont != null) {
      baseFont = customBaseFont;
      boldFont = customBoldFont ?? customBaseFont;
      italicFont = customItalicFont ?? customBaseFont;
    } else {
      try {
        baseFont = await PdfGoogleFonts.robotoRegular();
        boldFont = await PdfGoogleFonts.robotoBold();
        italicFont = await PdfGoogleFonts.robotoItalic();
      } catch (e) {
        debugPrint('Fallback font ke Helvetica: $e');
        baseFont = pw.Font.helvetica();
        boldFont = pw.Font.helveticaBold();
        italicFont = pw.Font.helveticaOblique();
      }
    }

    if (baseFont.fontName.toLowerCase().contains('helvetica')) {
      isFallbackFont = true;
    }

    String sanitizeText(String input) {
      if (!isFallbackFont) return input;
      return input
          .replaceAll('•', '-')
          .replaceAll('→', '->')
          .replaceAll('←', '<-')
          .replaceAll('≤', '<=')
          .replaceAll('≥', '>=')
          .replaceAll('≠', '!=')
          .replaceAll('“', '"')
          .replaceAll('”', '"')
          .replaceAll('‘', "'")
          .replaceAll('’', "'")
          .replaceAll('—', '-')
          .replaceAll('–', '-');
    }

    // 2. Parser Delta Ops dengan Line Buffer (Guardrail 2)
    final List<pw.Widget> contentWidgets = [];
    final List<_LineSegment> currentLine = [];
    int orderedListIndex = 1;

    void flushLine(Map<String, dynamic> lineAttrs) {
      if (currentLine.isEmpty) {
        contentWidgets.add(pw.SizedBox(height: 8));
        return;
      }

      final header = lineAttrs['header'];
      final listType = lineAttrs['list'];
      final isBlockquote = lineAttrs['blockquote'] == true;
      final isCodeBlock = lineAttrs['code-block'] == true;

      // Konversi segments menjadi pw.TextSpan
      final spans = currentLine.map((seg) {
        final text = sanitizeText(seg.text);
        final isBold = seg.attributes['bold'] == true;
        final isItalic = seg.attributes['italic'] == true;
        final isUnderline = seg.attributes['underline'] == true;

        pw.Font chosenFont = baseFont;
        if (isBold) {
          chosenFont = boldFont;
        } else if (isItalic) {
          chosenFont = italicFont;
        }

        return pw.TextSpan(
          text: text,
          style: pw.TextStyle(
            font: chosenFont,
            fontSize: header == 1 ? 18 : (header == 2 ? 15 : (header == 3 ? 13 : 11)),
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
            decoration: isUnderline ? pw.TextDecoration.underline : pw.TextDecoration.none,
            color: PdfColors.black,
          ),
        );
      }).toList();

      if (listType == 'ordered') {
        contentWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 20,
                  child: pw.Text('$orderedListIndex.', style: pw.TextStyle(font: boldFont, fontSize: 11)),
                ),
                pw.Expanded(
                  child: pw.RichText(text: pw.TextSpan(children: spans)),
                ),
              ],
            ),
          ),
        );
        orderedListIndex++;
      } else if (listType == 'bullet') {
        orderedListIndex = 1;
        contentWidgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 14, bottom: 4),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, right: 8),
                  child: pw.Container(
                    width: 4,
                    height: 4,
                    decoration: const pw.BoxDecoration(color: PdfColors.black, shape: pw.BoxShape.circle),
                  ),
                ),
                pw.Expanded(
                  child: pw.RichText(text: pw.TextSpan(children: spans)),
                ),
              ],
            ),
          ),
        );
      } else {
        orderedListIndex = 1;

        if (header != null) {
          contentWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 8, bottom: 4),
              child: pw.RichText(text: pw.TextSpan(children: spans)),
            ),
          );
        } else if (isCodeBlock) {
          contentWidgets.add(
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.grey300),
              ),
              child: pw.RichText(text: pw.TextSpan(children: spans)),
            ),
          );
        } else if (isBlockquote) {
          contentWidgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.only(left: 10, top: 2, bottom: 2),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: const pw.BoxDecoration(
                border: pw.Border(left: pw.BorderSide(color: PdfColors.teal, width: 3)),
              ),
              child: pw.RichText(text: pw.TextSpan(children: spans)),
            ),
          );
        } else {
          contentWidgets.add(
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 5),
              child: pw.RichText(text: pw.TextSpan(children: spans)),
            ),
          );
        }
      }

      currentLine.clear();
    }

    // 3. Iterasi Operasi Delta JSON
    final ops = deltaContent is List ? deltaContent : const [];
    for (final op in ops) {
      if (op is! Map) continue;
      final insert = op['insert'];
      final attrs = (op['attributes'] as Map?)?.cast<String, dynamic>() ?? const {};

      // Embed Image
      if (insert is Map && insert['image'] != null) {
        flushLine(const {});
        final imageUrl = insert['image'].toString();

        Uint8List? imageBytes;
        if (imageLoader != null) {
          imageBytes = await imageLoader(imageUrl);
        } else {
          try {
            final res = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 10));
            if (res.statusCode == 200) {
              imageBytes = res.bodyBytes;
            }
          } catch (e) {
            debugPrint('Gagal unduh gambar PDF: $e');
          }
        }

        if (imageBytes != null) {
          final image = pw.MemoryImage(imageBytes);
          contentWidgets.add(
            pw.Center(
              child: pw.ConstrainedBox(
                constraints: const pw.BoxConstraints(maxHeight: 320, maxWidth: 450),
                child: pw.Image(image, fit: pw.BoxFit.contain),
              ),
            ),
          );
          contentWidgets.add(pw.SizedBox(height: 10));
        } else {
          contentWidgets.add(
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.symmetric(vertical: 4),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text('[Gambar: $imageUrl]', style: pw.TextStyle(font: italicFont, fontSize: 9, color: PdfColors.grey700)),
            ),
          );
        }
        continue;
      }

      // Text Ops
      if (insert is String) {
        final parts = insert.split('\n');
        for (int i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.isNotEmpty) {
            currentLine.add(_LineSegment(part, attrs));
          }
          if (i < parts.length - 1) {
            flushLine(attrs);
          }
        }
      }
    }

    if (currentLine.isNotEmpty) {
      flushLine(const {});
    }

    // 4. Bangun MultiPage Document dengan Header & Footer
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        maxPages: 100,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 10),
            margin: const pw.EdgeInsets.only(bottom: 14),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Farlean LMS - Materi Pembelajaran', style: pw.TextStyle(font: baseFont, fontSize: 9, color: PdfColors.grey600)),
                pw.Text(sanitizeText(title), style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.grey800)),
              ],
            ),
          );
        },
        footer: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            margin: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Dicetak via Farlean LMS', style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey500)),
                pw.Text('Halaman ${ctx.pageNumber} dari ${ctx.pagesCount}', style: pw.TextStyle(font: baseFont, fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context ctx) => [
          // Judul Utama Materi
          pw.Text(sanitizeText(title), style: pw.TextStyle(font: boldFont, fontSize: 22, color: PdfColors.teal800)),
          if (subtitle != null && subtitle.trim().isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text(sanitizeText(subtitle), style: pw.TextStyle(font: italicFont, fontSize: 12, color: PdfColors.grey700)),
          ],
          pw.SizedBox(height: 14),
          pw.Divider(color: PdfColors.grey400, thickness: 1),
          pw.SizedBox(height: 12),

          // Konten Hasil Konversi Delta
          ...contentWidgets,
        ],
      ),
    );

    return pdf.save();
  }
}
