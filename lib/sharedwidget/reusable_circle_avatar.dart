// reusable_circle_avatar.dart
// Simple, reusable circular avatar widget for consistent profile UI.
//
// Example:
// ReusableCircleAvatar(
//   imageUrl: 'https://example.com/avatar.png',
//   radius: 30,
//   onTap: () => print('Avatar tapped'),
// );

import 'package:flutter/material.dart';

class ReusableCircleAvatar extends StatelessWidget {
  /// Local asset image path.
  final String? assetImage;

  /// Network image URL.
  final String? imageUrl;

  /// Initials or text shown when no image is available.
  final String? initials;

  /// Avatar radius.
  final double radius;

  /// Background color (used if no image).
  final Color backgroundColor;

  /// Text color for initials.
  final Color textColor;

  /// Optional border color and width.
  final Color? borderColor;
  final double borderWidth;

  /// Optional icon when no image or initials.
  final IconData? fallbackIcon;

  /// Optional tap action.
  final VoidCallback? onTap;

  const ReusableCircleAvatar({
    Key? key,
    this.assetImage,
    this.imageUrl,
    this.initials,
    this.radius = 24,
    this.backgroundColor = Colors.grey,
    this.textColor = Colors.white,
    this.borderColor,
    this.borderWidth = 0,
    this.fallbackIcon,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Widget child;

    // Priority: imageUrl → assetImage → initials → icon
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: NetworkImage(imageUrl!),
      );
    } else if (assetImage != null && assetImage!.isNotEmpty) {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage(assetImage!),
      );
    } else if (initials != null && initials!.isNotEmpty) {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Text(
          initials!.toUpperCase(),
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: radius * 0.6,
          ),
        ),
      );
    } else {
      child = CircleAvatar(
        radius: radius,
        backgroundColor: backgroundColor,
        child: Icon(fallbackIcon ?? Icons.person, color: textColor, size: radius),
      );
    }

    // Optional border
    if (borderWidth > 0 && borderColor != null) {
      child = Container(
        padding: EdgeInsets.all(borderWidth),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor!, width: borderWidth),
        ),
        child: ClipOval(child: child),
      );
    }

    // Optional tap
    if (onTap != null) {
      child = InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: child,
      );
    }

    return child;
  }
}
