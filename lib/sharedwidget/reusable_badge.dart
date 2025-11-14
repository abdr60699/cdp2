import 'package:flutter/material.dart';

class ReusableBadge extends StatelessWidget {
  final Widget child;
  final String? label;
  final int? count;
  final Color badgeColor;
  final Color textColor;
  final bool showBadge;
  final Alignment alignment;
  final double? size;

  const ReusableBadge({
    Key? key,
    required this.child,
    this.label,
    this.count,
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.showBadge = true,
    this.alignment = Alignment.topRight,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!showBadge) {
      return child;
    }

    String badgeText = '';
    if (label != null) {
      badgeText = label!;
    } else if (count != null) {
      badgeText = count! > 99 ? '99+' : count.toString();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (badgeText.isNotEmpty)
          Positioned(
            top: alignment == Alignment.topRight || alignment == Alignment.topLeft ? 0 : null,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight ? 0 : null,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft ? 0 : null,
            bottom: alignment == Alignment.bottomRight || alignment == Alignment.bottomLeft ? 0 : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: size ?? 18,
                minHeight: size ?? 18,
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
