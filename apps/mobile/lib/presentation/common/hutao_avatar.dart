import 'package:flutter/material.dart';

/// Komponen avatar terpusat Hutao-AI.
///
/// Menampilkan [assets/images/hutao_avatar.jpg] dalam bentuk lingkaran sempurna
/// via [ClipOval], dengan optimasi memori [cacheWidth]/[cacheHeight]
/// berbasis pixel-density aktual, serta fallback icon [Icons.auto_awesome_rounded]
/// agar seluruh widget test tetap lulus tanpa aset fisik.
///
/// Gunakan [isWarning] = true untuk menampilkan indikator peringatan (warna amber)
/// pada gelembung pesan error/ujian di AI Tutor Screen.
class HutaoAvatar extends StatelessWidget {
  final double size;
  final bool isWarning;

  const HutaoAvatar({
    super.key,
    this.size = 28,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final int cacheTarget = (size * pixelRatio).round().clamp(1, 512);

    // Jika status peringatan aktif, tampilkan icon warning amber
    // (bukan avatar Hutao) sesuai perilaku asli ai_tutor_screen.dart
    if (isWarning) {
      return CircleAvatar(
        radius: size / 2,
        backgroundColor: const Color(0xFFD97706).withAlpha(30), // AppTheme.warning
        child: Icon(
          Icons.warning_amber_rounded,
          size: size * 0.57,
          color: const Color(0xFFD97706),
        ),
      );
    }

    return ClipOval(
      child: Image.asset(
        'assets/images/hutao_avatar.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheTarget,
        cacheHeight: cacheTarget,
        semanticLabel: 'Hutao-AI Avatar',
        errorBuilder: (context, error, stackTrace) {
          // Fallback aman untuk flutter test environment
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: Theme.of(context).colorScheme.primary.withAlpha(25),
            child: Icon(
              Icons.auto_awesome_rounded,
              size: size * 0.57,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}
