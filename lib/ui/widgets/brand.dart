import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Asset paths for the BLOB brand marks.
class BrandAssets {
  BrandAssets._();

  /// Badge only (network ring + wheat/people/arrow motif), transparent bg.
  static const String mark = 'assets/images/blob_mark.png';

  /// Badge + "Blob" wordmark lockup, transparent bg.
  static const String lockup = 'assets/images/blob_logo_full.png';
}

/// The BLOB badge mark.
///
/// The supplied artwork is dark-teal on transparent, which reads poorly on the
/// dark green brand surfaces. Set [onDark] to render it inside a white
/// rounded tile so it keeps full contrast and colour fidelity anywhere.
class BlobMark extends StatelessWidget {
  final double size;
  final bool onDark;
  final double? radius;

  const BlobMark({super.key, this.size = 84, this.onDark = false, this.radius});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      BrandAssets.mark,
      width: onDark ? size * 0.9 : size,
      height: onDark ? size * 0.9 : size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => Icon(
        Icons.eco,
        size: (onDark ? size * 0.82 : size) * 0.6,
        color: AppColors.primary,
      ),
    );

    if (!onDark) return image;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius ?? size * 0.28),
      ),
      child: Center(child: image),
    );
  }
}

/// Badge + wordmark, for splash / welcome hero use.
class BlobLockup extends StatelessWidget {
  final double width;
  const BlobLockup({super.key, this.width = 180});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      BrandAssets.lockup,
      width: width,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => BlobMark(size: width * 0.6),
    );
  }
}

/// Small mark + "BLOB" text, sized for app bar titles.
class BrandAppBarTitle extends StatelessWidget {
  final String? title;
  const BrandAppBarTitle({super.key, this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BlobMark(size: 34),
        const SizedBox(width: 9),
        Text(title ?? 'BLOB'),
      ],
    );
  }
}
