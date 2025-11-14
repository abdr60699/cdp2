// reusable_svg_icon.dart
// ReusableSvgIcon — simple, reusable SVG icon widget.
//
// Requires flutter_svg in your pubspec.yaml:
// dependencies:
//   flutter_svg: ^1.1.0
//
// Example:
//   ReusableSvgIcon.asset('assets/icons/user.svg', width: 24, color: Colors.white);
//   ReusableSvgIcon.network('https://.../icon.svg', width: 32);

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReusableSvgIcon extends StatelessWidget {
  /// Path to a local SVG asset (exclusive with [networkUrl]).
  final String? assetName;

  /// URL to a remote SVG (exclusive with [assetName]).
  final String? networkUrl;

  /// Icon size
  final double? width;
  final double? height;

  /// Optional color tint (leave null for original SVG colors).
  final Color? color;

  /// BoxFit for scaling inside its box.
  final BoxFit fit;

  /// Accessibility label.
  final String? semanticsLabel;

  /// Widget to show while loading (for network SVGs).
  final Widget? placeholder;

  /// Optional tap callback.
  final VoidCallback? onTap;

  /// Color blending mode.
  final BlendMode colorBlendMode;

  const ReusableSvgIcon.asset(
    this.assetName, {
    Key? key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
    this.placeholder,
    this.onTap,
    this.colorBlendMode = BlendMode.srcIn,
  })  : networkUrl = null,
        super(key: key);

  const ReusableSvgIcon.network(
    this.networkUrl, {
    Key? key,
    this.width,
    this.height,
    this.color,
    this.fit = BoxFit.contain,
    this.semanticsLabel,
    this.placeholder,
    this.onTap,
    this.colorBlendMode = BlendMode.srcIn,
  })  : assetName = null,
        super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(
      (assetName != null) ^ (networkUrl != null),
      'Provide either assetName or networkUrl, not both.',
    );

    final svgWidget = assetName != null
        ? SvgPicture.asset(
            assetName!,
            width: width,
            height: height,
            fit: fit,
            semanticsLabel: semanticsLabel,
            colorFilter: color != null ? ColorFilter.mode(color!, colorBlendMode) : null,
            placeholderBuilder: (_) => placeholder ?? const SizedBox.shrink(),
          )
        : SvgPicture.network(
            networkUrl!,
            width: width,
            height: height,
            fit: fit,
            semanticsLabel: semanticsLabel,
            colorFilter: color != null ? ColorFilter.mode(color!, colorBlendMode) : null,
            placeholderBuilder: (_) => placeholder ?? const SizedBox.shrink(),
          );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(width: width, height: height, child: svgWidget),
      );
    }

    return SizedBox(width: width, height: height, child: svgWidget);
  }
}
