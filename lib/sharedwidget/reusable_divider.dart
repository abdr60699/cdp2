import 'package:flutter/material.dart';

class ReusableDivider extends StatelessWidget {
  final double? thickness;
  final double? height;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final bool isDashed;
  final String? text;
  final TextStyle? textStyle;

  const ReusableDivider({
    Key? key,
    this.thickness,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
    this.isDashed = false,
    this.text,
    this.textStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (text != null && text!.isNotEmpty) {
      return Row(
        children: [
          Expanded(
            child: _buildDivider(context),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              text!,
              style: textStyle ?? TextStyle(color: Colors.grey.shade600),
            ),
          ),
          Expanded(
            child: _buildDivider(context),
          ),
        ],
      );
    }

    return _buildDivider(context);
  }

  Widget _buildDivider(BuildContext context) {
    if (isDashed) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final boxWidth = constraints.constrainWidth();
          const dashWidth = 5.0;
          const dashSpace = 3.0;
          final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
          return Flex(
            direction: Axis.horizontal,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(dashCount, (_) {
              return SizedBox(
                width: dashWidth,
                height: thickness ?? 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color ?? Colors.grey.shade300,
                  ),
                ),
              );
            }),
          );
        },
      );
    }

    return Divider(
      thickness: thickness,
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: color,
    );
  }
}
