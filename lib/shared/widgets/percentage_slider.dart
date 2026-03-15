import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class PercentageSlider extends StatefulWidget {
  const PercentageSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.divisions,
    this.onChangeEnd,
  });

  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChangeEnd;

  @override
  State<PercentageSlider> createState() => _PercentageSliderState();
}

class _PercentageSliderState extends State<PercentageSlider> {
  int? _lastHapticValue;

  @override
  void didUpdateWidget(covariant PercentageSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value.round() != widget.value.round()) {
      _lastHapticValue = widget.value.round();
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${widget.value.round()}%',
          style: AppTextStyles.headingLarge(palette),
        ),
        const SizedBox(height: AppSpacing.sm),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: palette.safe,
            inactiveTrackColor: palette.surfaceElevated,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 0,
              pressedElevation: 0,
            ),
          ),
          child: Slider(
            value: widget.value,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: (value) {
              _triggerHapticIfNeeded(value);
              widget.onChanged(value);
            },
            onChangeEnd: widget.onChangeEnd,
          ),
        ),
      ],
    );
  }

  void _triggerHapticIfNeeded(double value) {
    final current = value.round();
    if (_lastHapticValue == null) {
      _lastHapticValue = current;
      return;
    }
    if (current != _lastHapticValue) {
      HapticFeedback.selectionClick();
      _lastHapticValue = current;
    }
  }
}
