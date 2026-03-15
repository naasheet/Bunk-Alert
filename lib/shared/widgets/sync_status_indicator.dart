import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/shared/providers/connectivity_provider.dart';

enum SyncIndicatorState {
  synced,
  syncing,
  offline,
}

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({
    super.key,
    required this.state,
  });

  final SyncIndicatorState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final isOffline = ref.watch(connectivityProvider).maybeWhen(
          data: (offline) => offline,
          orElse: () => false,
        );
    final effectiveState =
        isOffline ? SyncIndicatorState.offline : state;

    switch (effectiveState) {
      case SyncIndicatorState.syncing:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: palette.textSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Syncing',
              style: AppTextStyles.caption(palette)
                  .copyWith(color: palette.textSecondary),
            ),
          ],
        );
      case SyncIndicatorState.offline:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 14,
              color: palette.warning,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Offline',
              style: AppTextStyles.caption(palette)
                  .copyWith(color: palette.warning),
            ),
          ],
        );
      case SyncIndicatorState.synced:
      default:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              size: 14,
              color: palette.safe,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Synced',
              style: AppTextStyles.caption(palette)
                  .copyWith(color: palette.safe),
            ),
          ],
        );
    }
  }
}
