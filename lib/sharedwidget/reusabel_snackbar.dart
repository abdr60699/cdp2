// reuabel_snackbar.dart
// Simple, reusable snackbar helper with minimal, important properties.
// Use the 'Reuabel' prefix for future reusable widgets as requested.

import 'package:flutter/material.dart';

/// Lightweight types to pick a sensible default style.
enum ReusabelSnackType { plain, success, error, info, warning }

class ReusabelSnackbar {
  ReusabelSnackbar._(); // static-only

  /// Show a snackbar.
  ///
  /// Required:
  ///  - context
  ///  - message
  ///
  /// Optional (kept minimal):
  ///  - type: selects default color + icon
  ///  - duration: how long it stays
  ///  - actionLabel + onAction: optional action button
  ///  - backgroundColor: to override default color
  static void show(
    BuildContext context, {
    required String message,
    ReusabelSnackType type = ReusabelSnackType.plain,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
    Color? backgroundColor,
    bool floating = true,
  }) {
    final theme = Theme.of(context);
    final data = _styleForType(theme, type);

    final bg = backgroundColor ?? data.backgroundColor;
    final icon = data.icon;

    final content = Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
        ],
        Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white))),
      ],
    );

    final snack = SnackBar(
      content: content,
      duration: duration,
      behavior: floating ? SnackBarBehavior.floating : SnackBarBehavior.fixed,
      backgroundColor: bg,
      action: (actionLabel != null && onAction != null)
          ? SnackBarAction(
              label: actionLabel, onPressed: onAction, textColor: Colors.white)
          : null,
      margin: floating
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
          : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  /// Convenience wrappers:
  static void success(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context,
          message: message,
          type: ReusabelSnackType.success,
          actionLabel: actionLabel,
          onAction: onAction);

  static void error(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context,
          message: message,
          type: ReusabelSnackType.error,
          actionLabel: actionLabel,
          onAction: onAction);

  static void info(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context,
          message: message,
          type: ReusabelSnackType.info,
          actionLabel: actionLabel,
          onAction: onAction);

  static void warning(BuildContext context, String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      show(context,
          message: message,
          type: ReusabelSnackType.warning,
          actionLabel: actionLabel,
          onAction: onAction);
}

/// Internal simple mapping from type -> color/icon
class _SnackStyle {
  final Color backgroundColor;
  final IconData? icon;
  const _SnackStyle({required this.backgroundColor, this.icon});
}

_SnackStyle _styleForType(ThemeData theme, ReusabelSnackType type) {
  switch (type) {
    case ReusabelSnackType.success:
      return _SnackStyle(
          backgroundColor: Colors.green.shade600,
          icon: Icons.check_circle_outline);
    case ReusabelSnackType.error:
      return _SnackStyle(
          backgroundColor: Colors.red.shade700, icon: Icons.error_outline);
    case ReusabelSnackType.info:
      return _SnackStyle(
          backgroundColor: Colors.blue.shade700, icon: Icons.info_outline);
    case ReusabelSnackType.warning:
      return _SnackStyle(
          backgroundColor: Colors.orange.shade800,
          icon: Icons.warning_amber_outlined);
    case ReusabelSnackType.plain:
    default:
      return _SnackStyle(
          backgroundColor: theme.colorScheme.surface.withOpacity(0.95),
          icon: null);
  }
}

/// Convenience extension for context.showX()
extension ReusabelSnackbarExt on BuildContext {
  void showReuabel(String message,
      {ReusabelSnackType type = ReusabelSnackType.plain,
      Duration duration = const Duration(seconds: 3),
      String? actionLabel,
      VoidCallback? onAction,
      Color? backgroundColor}) {
    ReusabelSnackbar.show(
      this,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
      backgroundColor: backgroundColor,
    );
  }

  void showReuabelSuccess(String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      ReusabelSnackbar.success(this, message,
          actionLabel: actionLabel, onAction: onAction);
  void showReuabelError(String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      ReusabelSnackbar.error(this, message,
          actionLabel: actionLabel, onAction: onAction);
  void showReuabelInfo(String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      ReusabelSnackbar.info(this, message,
          actionLabel: actionLabel, onAction: onAction);
  void showReuabelWarning(String message,
          {String? actionLabel, VoidCallback? onAction}) =>
      ReusabelSnackbar.warning(this, message,
          actionLabel: actionLabel, onAction: onAction);
}
