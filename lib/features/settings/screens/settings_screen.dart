
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import 'package:bunk_alert/core/router/route_names.dart';
import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/database/local_database_service.dart';
import 'package:bunk_alert/data/export/csv_exporter.dart';
import 'package:bunk_alert/data/firebase/firestore_service.dart';
import 'package:bunk_alert/data/notifications/fcm_service.dart';
import 'package:bunk_alert/data/notifications/notification_scheduler_service.dart';
import 'package:bunk_alert/data/repositories/attendance_repository.dart';
import 'package:bunk_alert/data/repositories/auth_repository.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/sync/cloud_sync_service.dart';
import 'package:bunk_alert/shared/auth/app_auth.dart';
import 'package:bunk_alert/shared/utils/error_message_mapper.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/confirmation_dialog.dart';
import 'package:bunk_alert/shared/widgets/ghost_button.dart';
import 'package:bunk_alert/shared/widgets/percentage_slider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsRepository _settingsRepository =
      SettingsRepository.instance;
  final NotificationSchedulerService _scheduler =
      NotificationSchedulerService.instance;
  final AttendanceRepository _attendanceRepository = AttendanceRepository();
  final AuthRepository _authRepository = AuthRepository();
  final CloudSyncService _cloudSyncService = CloudSyncService.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final LocalDatabaseService _localDatabaseService =
      LocalDatabaseService.instance;

  bool _classRemindersEnabled = true;
  bool _riskAlertsEnabled = true;
  int _leadTimeMinutes = 10;
  double? _globalTarget;
  double _targetPercent = 75;
  ThemeMode _themeMode = ThemeMode.system;

  bool _isExporting = false;
  bool _isBackingUp = false;
  bool _isResetting = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final classReminders =
        await _settingsRepository.getClassRemindersEnabled();
    final riskAlerts = await _settingsRepository.getRiskAlertsEnabled();
    final leadTime =
        await _settingsRepository.getReminderLeadTimeMinutes();
    final globalTarget =
        await _settingsRepository.getGlobalTargetPercentage();
    final themeMode = await _settingsRepository.getThemeMode();
    if (!mounted) {
      return;
    }
    setState(() {
      _classRemindersEnabled = classReminders;
      _riskAlertsEnabled = riskAlerts;
      _leadTimeMinutes = leadTime;
      _globalTarget = globalTarget;
      _targetPercent = globalTarget;
      _themeMode = themeMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final user = AppAuth.currentUser;

    return AppScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.base,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Settings',
                        style: AppTextStyles.headingSmall(palette),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Account'),
                    _AccountCard(
                      user: user,
                      onSignOut: _signOut,
                      onEditName: _editDisplayName,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(title: 'Appearance'),
                    Row(
                      children: [
                        Expanded(
                          child: _ThemeChip(
                            label: 'System',
                            isSelected: _themeMode == ThemeMode.system,
                            onTap: () => _setTheme(ThemeMode.system),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ThemeChip(
                            label: 'Light',
                            isSelected: _themeMode == ThemeMode.light,
                            onTap: () => _setTheme(ThemeMode.light),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _ThemeChip(
                            label: 'Dark',
                            isSelected: _themeMode == ThemeMode.dark,
                            onTap: () => _setTheme(ThemeMode.dark),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(title: 'Defaults'),
                    _DefaultsCard(
                      targetPercent: _targetPercent,
                      globalTarget: _globalTarget,
                      onChanged: (value) {
                        setState(() {
                          _targetPercent = value;
                        });
                      },
                      onChangeEnd: _setGlobalTarget,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(title: 'Notifications'),
                    _SettingRow(
                      label: 'Class reminders',
                      child: _SlideToggle(
                        value: _classRemindersEnabled,
                        onChanged: _toggleClassReminders,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingRow(
                      label: 'Risk alerts',
                      child: _SlideToggle(
                        value: _riskAlertsEnabled,
                        onChanged: _toggleRiskAlerts,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Lead time',
                      style: AppTextStyles.labelSmall(palette),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        _LeadTimeOption(
                          label: '5 min',
                          isSelected: _leadTimeMinutes == 5,
                          onTap: () => _setLeadTime(5),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _LeadTimeOption(
                          label: '10 min',
                          isSelected: _leadTimeMinutes == 10,
                          onTap: () => _setLeadTime(10),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _LeadTimeOption(
                          label: '15 min',
                          isSelected: _leadTimeMinutes == 15,
                          onTap: () => _setLeadTime(15),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(title: 'Data'),
                    _ActionTile(
                      icon: Icons.download_outlined,
                      label: 'Export to CSV',
                      isLoading: _isExporting,
                      onTap: _exportToCsv,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _ActionTile(
                      icon: Icons.cloud_upload_outlined,
                      label: 'Backup to Cloud',
                      isLoading: _isBackingUp,
                      onTap: _backupToCloud,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    _SectionHeader(title: 'Danger Zone'),
                    _DangerTile(
                      label: 'Reset All Data',
                      isLoading: _isResetting,
                      onTap: _confirmReset,
                    ),
                    const SizedBox(height: AppSpacing.section),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setTheme(ThemeMode mode) async {
    if (_themeMode == mode) {
      return;
    }
    setState(() {
      _themeMode = mode;
    });
    await _settingsRepository.setThemeMode(mode);
  }

  Future<void> _toggleClassReminders(bool value) async {
    setState(() {
      _classRemindersEnabled = value;
    });
    await _settingsRepository.setClassRemindersEnabled(value);
    if (value) {
      await _scheduler.rescheduleClassReminders();
      await FcmService.instance.requestPermissionsIfReady(context);
    } else {
      await _scheduler.cancelClassReminders();
    }
  }

  Future<void> _toggleRiskAlerts(bool value) async {
    setState(() {
      _riskAlertsEnabled = value;
    });
    await _settingsRepository.setRiskAlertsEnabled(value);
    if (value) {
      await _scheduler.checkAndScheduleRiskAlerts();
    } else {
      await _scheduler.cancelRiskAlerts();
    }
  }

  Future<void> _setLeadTime(int minutes) async {
    if (_leadTimeMinutes == minutes) {
      return;
    }
    setState(() {
      _leadTimeMinutes = minutes;
    });
    await _settingsRepository.setReminderLeadTimeMinutes(minutes);
    if (_classRemindersEnabled) {
      await _scheduler.rescheduleClassReminders();
    }
  }

  Future<void> _setGlobalTarget(double value) async {
    final globalTarget = _globalTarget;
    if (globalTarget != null && value == globalTarget) {
      return;
    }
    await _settingsRepository.setGlobalTargetPercentage(value);
    setState(() {
      _globalTarget = value;
    });
  }

  Future<void> _signOut() async {
    try {
      await _authRepository.signOut();
      if (!mounted) {
        return;
      }
      context.go(RouteNames.login);
    } on FirebaseException catch (error) {
      _showSnack(friendlyErrorMessage(error));
    } catch (_) {
      _showSnack('Unable to sign out. Please try again.');
    }
  }

  Future<void> _editDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnack('Please sign in to edit your name.');
      return;
    }
    var updatedName = user.displayName?.trim() ?? '';
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Edit name'),
          content: TextFormField(
            initialValue: updatedName,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
            onChanged: (value) {
              updatedName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(updatedName),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null) {
      return;
    }
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      _showSnack('Name cannot be empty.');
      return;
    }
    try {
      await user.updateDisplayName(trimmed);
      await user.reload();
      final target =
          await _settingsRepository.getGlobalTargetPercentage();
      await _firestoreService.upsertUserProfile(
        userId: user.uid,
        name: trimmed,
        email: user.email?.trim() ?? '',
        targetPercentage: target.round(),
        setCreatedAt: false,
      );
      if (!mounted) {
        return;
      }
      setState(() {});
      _showSnack('Name updated.');
    } on FirebaseException catch (error) {
      _showSnack(friendlyErrorMessage(error));
    } catch (_) {
      _showSnack('Unable to update name.');
    }
  }

  Future<void> _exportToCsv() async {
    if (_isExporting) {
      return;
    }
    setState(() {
      _isExporting = true;
    });
    try {
      await CsvExporter.export();
      _showSnack('CSV export ready.');
    } catch (_) {
      _showSnack('Unable to export CSV.');
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _backupToCloud() async {
    if (_isBackingUp) {
      return;
    }
    final userId = AppAuth.currentUser?.uid;
    if (userId == null) {
      _showSnack('Please sign in to back up.');
      return;
    }
    setState(() {
      _isBackingUp = true;
    });
    try {
      final count =
          await _attendanceRepository.syncPendingRecords(userId: userId);
      await _cloudSyncService.syncAll(
        userId: userId,
        forceFullSync: true,
      );
      _showSnack(
        count == 0
            ? 'Backed up subjects and timetable.'
            : 'Backed up $count records plus subjects and timetable.',
      );
    } on FirebaseException catch (error) {
      _showSnack(friendlyErrorMessage(error));
    } catch (_) {
      _showSnack('Backup failed. Try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isBackingUp = false;
        });
      }
    }
  }

  Future<void> _confirmReset() async {
    if (_isResetting) {
      return;
    }
    final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return const ConfirmationDialog(
              title: 'Are you sure?',
              message:
                  'This will remove all local and cloud data for this account.',
              confirmLabel: 'Continue',
              isDestructive: true,
            );
          },
        ) ??
        false;

    if (!shouldContinue) {
      return;
    }

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return const ConfirmationDialog(
              title: 'Type DELETE to confirm',
              message: 'This action cannot be undone.',
              confirmLabel: 'Reset',
              isDestructive: true,
              requireDeleteText: true,
            );
          },
        ) ??
        false;

    if (!confirmed) {
      _showSnack('Reset cancelled.');
      return;
    }

    await _resetAllData();
  }

  Future<void> _resetAllData() async {
    setState(() {
      _isResetting = true;
    });
    try {
      final userId = AppAuth.currentUser?.uid;
      final isar = _localDatabaseService.isar;
      await isar.writeTxn(() async {
        await isar.clear();
      });
      await _settingsRepository.resetAll();
      await _scheduler.cancelClassReminders();
      await _scheduler.cancelRiskAlerts();

      if (userId != null) {
        await _clearFirestoreData(userId);
      }

      if (!mounted) {
        return;
      }
      context.go(RouteNames.home);
    } on FirebaseException catch (error) {
      _showSnack(friendlyErrorMessage(error));
    } catch (_) {
      _showSnack('Unable to reset data.');
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  Future<void> _clearFirestoreData(String userId) async {
    await _deleteCollection(_firestoreService.userSubjectsCollection(userId));
    await _deleteCollection(
      _firestoreService.userTimetableCollection(userId),
    );
    await _deleteCollection(
      _firestoreService.userAttendanceCollection(userId),
    );
    await _deleteCollection(_firestoreService.userFcmTokensCollection(userId));
    await _firestoreService.userProfileDoc(userId).delete();

    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: userId)
        .get();
    for (final doc in groupsSnapshot.docs) {
      await doc.reference.update({
        'members': FieldValue.arrayRemove([userId]),
      });
      await doc.reference
          .collection('attendance_summary')
          .doc(userId)
          .delete();
    }
  }

  Future<void> _deleteCollection(
    CollectionReference<Map<String, dynamic>> collection,
  ) async {
    var snapshot = await collection.limit(200).get();
    while (snapshot.docs.isNotEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      snapshot = await collection.limit(200).get();
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.labelSmall(palette)
            .copyWith(letterSpacing: 1.1),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.user,
    required this.onSignOut,
    required this.onEditName,
  });

  final User? user;
  final VoidCallback onSignOut;
  final VoidCallback onEditName;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final displayName = user?.displayName?.trim();
    final email = user?.email?.trim();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _UserAvatar(user: user),
              const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName?.isNotEmpty == true
                                    ? displayName!
                                    : 'Student',
                                style: AppTextStyles.headingSmall(palette),
                              ),
                            ),
                            TextButton(
                              onPressed: onEditName,
                              child: const Text('Edit'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          email?.isNotEmpty == true ? email! : 'No email',
                      style: AppTextStyles.bodySmall(palette),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              label: 'Sign Out',
              onPressed: onSignOut,
            ),
          ),
        ],
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final photoUrl = user?.photoURL;
    final fallback = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()[0].toUpperCase()
        : 'U';

    return CircleAvatar(
      radius: 26,
      backgroundColor: palette.surface,
      backgroundImage:
          photoUrl == null ? null : CachedNetworkImageProvider(photoUrl),
      child: photoUrl == null
          ? Text(
              fallback,
              style: AppTextStyles.headingSmall(palette),
            )
          : null,
    );
  }
}

class _ThemeChip extends StatelessWidget {
  const _ThemeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final background =
        isSelected ? palette.surfaceElevated : palette.surface;
    final borderColor = isSelected ? palette.chartLine : palette.border;
    final textColor =
        isSelected ? palette.textPrimary : palette.textSecondary;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
          border: Border.all(color: borderColor),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium(palette)
                .copyWith(color: textColor),
          ),
        ),
      ),
    );
  }
}

class _DefaultsCard extends StatelessWidget {
  const _DefaultsCard({
    required this.targetPercent,
    required this.globalTarget,
    required this.onChanged,
    required this.onChangeEnd,
  });

  final double targetPercent;
  final double? globalTarget;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final defaultValue = globalTarget ?? targetPercent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: palette.surfaceElevated,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PercentageSlider(
            value: targetPercent,
            min: 50,
            max: 100,
            divisions: 50,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
          Text(
            'Using default (${defaultValue.round()}%). Applies to subjects without a custom target.',
            style: AppTextStyles.caption(palette),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium(palette),
        ),
        child,
      ],
    );
  }
}

class _SlideToggle extends StatelessWidget {
  const _SlideToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Animate(
        target: value ? 1 : 0,
        effects: [
          CustomEffect(
            duration: 220.ms,
            curve: Curves.easeInOut,
            builder: (context, t, _) {
              final background = Color.lerp(
                palette.surfaceElevated,
                palette.safe,
                t,
              )!;
              final knobColor = Color.lerp(
                palette.textTertiary,
                palette.background,
                t,
              )!;
              final alignment = Alignment.lerp(
                Alignment.centerLeft,
                Alignment.centerRight,
                t,
              )!;
              return Container(
                width: 48,
                height: 28,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: alignment,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: knobColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        child: Container(
          width: 48,
          height: 28,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: palette.surfaceElevated,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: palette.textTertiary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeadTimeOption extends StatelessWidget {
  const _LeadTimeOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final background =
        isSelected ? palette.surfaceElevated : palette.surface;
    final textColor =
        isSelected ? palette.textPrimary : palette.textTertiary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Animate(
          target: isSelected ? 1 : 0,
          effects: [
            CustomEffect(
              duration: 220.ms,
              curve: Curves.easeInOut,
              builder: (context, t, _) {
                final animatedBackground = Color.lerp(
                  palette.surface,
                  palette.surfaceElevated,
                  t,
                )!;
                final animatedText = Color.lerp(
                  palette.textTertiary,
                  palette.textPrimary,
                  t,
                )!;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: animatedBackground,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.chipRadius),
                    border: Border.all(color: palette.border),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: AppTextStyles.labelMedium(palette)
                          .copyWith(color: animatedText),
                    ),
                  ),
                );
              },
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(AppSpacing.chipRadius),
              border: Border.all(color: palette.border),
            ),
            child: Center(
              child: Text(
                label,
                style: AppTextStyles.labelMedium(palette)
                    .copyWith(color: textColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: palette.textPrimary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(palette),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.textPrimary,
                ),
              )
            else
              Icon(
                Icons.chevron_right,
                color: palette.textTertiary,
              ),
          ],
        ),
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;

    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: palette.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: palette.border),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_outlined, color: palette.danger),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodyMedium(palette)
                    .copyWith(color: palette.danger),
              ),
            ),
            if (isLoading)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.danger,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
