import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.decimals = 1,
    this.textStyle,
  });

  final double value;
  final int decimals;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Animate(
      key: ValueKey(value),
      effects: [
        CustomEffect(
          duration: 1200.ms,
          curve: Curves.easeOut,
          builder: (context, current, _) {
            final display = (value * current).toStringAsFixed(decimals);
            return Text(
              '$display%',
              style: textStyle ?? DefaultTextStyle.of(context).style,
            );
          },
        ),
      ],
      child: const SizedBox.shrink(),
    );
  }
}
