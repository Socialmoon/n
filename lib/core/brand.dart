import 'package:flutter/material.dart';

class AppBrand {
  const AppBrand._();

  static const String appName = 'Apne Saathi';
  static const String tagline = 'Trusted support network for members';
  static const String logoAsset = 'logos/logo2.png';
}

class BrandLogo extends StatelessWidget {
  const BrandLogo({
    this.size = 56,
    this.withBackdrop = true,
    super.key,
  });

  final double size;
  final bool withBackdrop;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      AppBrand.logoAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );

    if (!withBackdrop) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: image,
      );
    }

    return Container(
      width: size + 14,
      height: size + 14,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular((size + 14) * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: image,
      ),
    );
  }
}

class BrandedScreenTitle extends StatelessWidget {
  const BrandedScreenTitle(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const BrandLogo(size: 28, withBackdrop: false),
        const SizedBox(width: 10),
        Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
