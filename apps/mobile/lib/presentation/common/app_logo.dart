import 'package:flutter/material.dart';

/// Komponen logo terpusat Farlean LMS.
///
/// Menampilkan [assets/images/logo_farlean.jpg] dengan optimasi memori
/// via [cacheWidth]/[cacheHeight] berbasis pixel-density aktual,
/// radius sudut proporsional 22% dari [size], serta fallback icon
/// [Icons.school_rounded] agar seluruh widget test tetap lulus tanpa aset fisik.
class AppLogo extends StatelessWidget {
  final double size;

  /// Saat [isCompact] = true, logo ditampilkan tanpa padding luar tambahan
  /// agar muat di AppBar yang sempit (misal Dashboard: size 26).
  final bool isCompact;

  const AppLogo({
    super.key,
    this.size = 48,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final double radius = size * 0.22;
    final double pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final int cacheTarget = (size * pixelRatio).round().clamp(1, 512);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        'assets/images/logo_farlean.jpg',
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: cacheTarget,
        cacheHeight: cacheTarget,
        semanticLabel: 'Farlean LMS Logo',
        errorBuilder: (context, error, stackTrace) {
          // Fallback aman untuk flutter test environment
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Icon(
              Icons.school_rounded,
              size: size * 0.6,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }
}
