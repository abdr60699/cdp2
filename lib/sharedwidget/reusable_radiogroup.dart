// reusable_radio_group.dart
import 'package:flutter/material.dart';

class ReusableRadioGroup<T> extends StatelessWidget {
  final List<T> items;
  final T? value;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;
  final Widget Function(BuildContext, T, bool)? itemBuilder; // (ctx, item, selected)
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  final bool enabled;

  const ReusableRadioGroup({
    Key? key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.labelBuilder,
    this.itemBuilder,
    this.direction = Axis.vertical,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.spacing = 8.0,
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final children = items.map((it) {
      final selected = it == value;
      
      if (itemBuilder != null) {
        return GestureDetector(
          onTap: enabled ? () => onChanged(it) : null,
          child: itemBuilder!(context, it, selected),
        );
      }

      final label = labelBuilder != null ? labelBuilder!(it) : it.toString();
      
      return GestureDetector(
        onTap: enabled ? () => onChanged(it) : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Radio<T>(
              value: it,
              groupValue: value,
              onChanged: enabled ? (val) => onChanged(val as T) : null,
            ),
            Flexible(child: Text(label)),
          ],
        ),
      );
    }).toList();

    return direction == Axis.vertical
        ? Column(
            children: children
                .map((w) => Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: w,
                    ))
                .toList(),
          )
        : Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: children,
          );
  }
}