// reusable_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum ReusableDatePickerMode { date, time, dateTime }

class ReusableDatePicker extends StatefulWidget {
  final ReusableDatePickerMode mode;
  final DateTime? initialDateTime;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Locale? locale;
  final String? label;
  final String? hint;
  final ValueChanged<DateTime>? onChanged;
  final bool enabled;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final DateFormat? dateFormat; // requires intl package

  const ReusableDatePicker({
    super.key,
    this.mode = ReusableDatePickerMode.date,
    this.initialDateTime,
    this.firstDate,
    this.lastDate,
    this.locale,
    this.label,
    this.hint,
    this.onChanged,
    this.enabled = true,
    this.textStyle,
    this.decoration,
    this.dateFormat,
  });

  @override
  State<ReusableDatePicker> createState() => _ReusableDatePickerState();
}

class _ReusableDatePickerState extends State<ReusableDatePicker> {
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDateTime;
  }

  String _displayText() {
    if (_selected == null) return widget.hint ?? '';

    if (widget.mode == ReusableDatePickerMode.time) {
      final t = TimeOfDay.fromDateTime(_selected!);
      return t.format(context);
    } else {
      final fmt = widget.dateFormat ?? DateFormat.yMMMd(); // needs intl
      return fmt.format(_selected!);
    }
  }

  Future<void> _pick() async {
    if (!widget.enabled) return;

    if (widget.mode == ReusableDatePickerMode.time) {
      final initial = _selected != null
          ? TimeOfDay.fromDateTime(_selected!)
          : TimeOfDay.now();

      final t = await showTimePicker(context: context, initialTime: initial);
      if (t != null) {
        final now = DateTime.now();
        final dt = DateTime(now.year, now.month, now.day, t.hour, t.minute);
        setState(() => _selected = dt);
        widget.onChanged?.call(dt);
      }
      return;
    }

    // date or dateTime
    final now = DateTime.now();
    final initial = _selected ?? widget.initialDateTime ?? now;
    final first = widget.firstDate ?? DateTime(1900);
    final last = widget.lastDate ?? DateTime(2100);

    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      locale: widget.locale,
    );

    if (d != null) {
      if (widget.mode == ReusableDatePickerMode.dateTime) {
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(_selected ?? DateTime.now()),
        );
        final dt =
            DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
        setState(() => _selected = dt);
        widget.onChanged?.call(dt);
      } else {
        setState(() => _selected = d);
        widget.onChanged?.call(d);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoration = widget.decoration ??
        InputDecoration(labelText: widget.label, hintText: widget.hint);

    return GestureDetector(
      onTap: _pick,
      child: InputDecorator(
        decoration: decoration,
        child: Text(
          _displayText(),
          style: widget.textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
