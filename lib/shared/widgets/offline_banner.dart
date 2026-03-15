import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';

class OfflineBanner extends StatefulWidget {
  const OfflineBanner({super.key});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<dynamic>? _subscription;
  _BannerState _state = _BannerState.hidden;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    _setInitialStatus();
    _subscription = _connectivity.onConnectivityChanged.listen((event) {
      _handleConnectivityChange(_isOfflineFromEvent(event));
    });
  }

  Future<void> _setInitialStatus() async {
    final result = await _connectivity.checkConnectivity();
    _handleConnectivityChange(_isOfflineFromEvent(result));
  }

  bool _isOfflineFromEvent(dynamic event) {
    if (event is ConnectivityResult) {
      return event == ConnectivityResult.none;
    }
    if (event is List<ConnectivityResult>) {
      return event.isEmpty || event.contains(ConnectivityResult.none);
    }
    return true;
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isVisible = _state != _BannerState.hidden;
    return _buildBanner(context)
        .animate(target: isVisible ? 1 : 0)
        .slideY(
          begin: -1,
          end: 0,
          duration: 240.ms,
          curve: Curves.easeOut,
        )
        .fade(
          duration: 240.ms,
          curve: Curves.easeOut,
          begin: 0,
          end: 1,
        )
        .visibility(maintain: false);
  }

  Widget _buildBanner(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final message = switch (_state) {
      _BannerState.offline =>
        'You\'re offline - changes saved locally.',
      _BannerState.onlineSyncing => 'Back online - syncing...',
      _BannerState.hidden => '',
    };
    final textColor = _state == _BannerState.offline
        ? palette.warning
        : palette.textSecondary;
    return Material(
      color: palette.surfaceElevated,
      child: SafeArea(
        bottom: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.sm,
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium(palette)
                .copyWith(color: textColor),
          ),
        ),
      ),
    );
  }

  void _handleConnectivityChange(bool isOffline) {
    _hideTimer?.cancel();
    if (isOffline) {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _BannerState.offline;
      });
      return;
    }

    if (!mounted) {
      return;
    }
    if (_state == _BannerState.hidden) {
      return;
    }
    setState(() {
      _state = _BannerState.onlineSyncing;
    });
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) {
        return;
      }
      setState(() {
        _state = _BannerState.hidden;
      });
    });
  }
}

enum _BannerState {
  hidden,
  offline,
  onlineSyncing,
}

