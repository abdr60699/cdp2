// reusable_refresh_indicator.dart
// A simple yet flexible reusable RefreshIndicator for Flutter apps.
// Place this in `lib/widgets/` and import as:
// import 'widgets/reusable_refresh_indicator.dart';

import 'package:flutter/material.dart';

/// A reusable wrapper around [RefreshIndicator] that allows you to:
/// - Easily trigger pull-to-refresh for any scrollable content.
/// - Customize color, background, and behavior.
/// - Provide async refresh logic via [onRefresh].
/// - Optionally show a loading overlay (for non-scroll refresh use cases).
class ReusableRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;

  /// Customize colors (optional)
  final Color? color;
  final Color? backgroundColor;
  final double displacement;

  /// Optional: show refresh indicator even when the list is not scrollable
  final bool alwaysScrollable;

  /// Optional: add a manual refresh overlay for other async states
  final bool showLoadingOverlay;
  final bool isLoading;

  const ReusableRefreshIndicator({
    Key? key,
    required this.child,
    required this.onRefresh,
    this.color,
    this.backgroundColor,
    this.displacement = 40.0,
    this.alwaysScrollable = true,
    this.showLoadingOverlay = false,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final content = RefreshIndicator(
      color: color ?? Theme.of(context).colorScheme.primary,
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      displacement: displacement,
      onRefresh: onRefresh,
      triggerMode: alwaysScrollable
          ? RefreshIndicatorTriggerMode.anywhere
          : RefreshIndicatorTriggerMode.onEdge,
      child: alwaysScrollable
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: child,
            )
          : child,
    );

    if (showLoadingOverlay && isLoading) {
      return Stack(
        children: [
          content,
          Container(
            color: Colors.black.withOpacity(0.2),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      );
    }

    return content;
  }
}
