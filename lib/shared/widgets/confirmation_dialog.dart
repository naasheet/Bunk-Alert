import 'package:flutter/material.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.cancelLabel = 'Cancel',
    this.isDestructive = false,
    this.requireDeleteText = false,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool isDestructive;
  final bool requireDeleteText;

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isConfirmEnabled {
    if (!widget.requireDeleteText) {
      return true;
    }
    return _controller.text.trim().toUpperCase() == 'DELETE';
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final confirmColor = widget.isDestructive ? palette.danger : palette.chartLine;
    final confirmTextColor = widget.isDestructive ? palette.background : palette.background;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.lg,
      ),
      backgroundColor: palette.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.sheetRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: AppTextStyles.headingSmall(palette),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.message,
              style: AppTextStyles.bodySmall(palette),
            ),
            if (widget.requireDeleteText) ...[
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _controller,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Type DELETE to confirm',
                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text(widget.cancelLabel),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: _isConfirmEnabled
                        ? () => Navigator.of(context).pop(true)
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: confirmColor,
                      foregroundColor: confirmTextColor,
                    ),
                    child: Text(widget.confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
