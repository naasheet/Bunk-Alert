import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import 'package:bunk_alert/core/theme/app_colors.dart';
import 'package:bunk_alert/core/theme/app_spacing.dart';
import 'package:bunk_alert/core/theme/app_text_styles.dart';
import 'package:bunk_alert/data/models/subject_model.dart';
import 'package:bunk_alert/data/notifications/fcm_service.dart';
import 'package:bunk_alert/data/repositories/settings_repository.dart';
import 'package:bunk_alert/data/repositories/subject_repository.dart';
import 'package:bunk_alert/shared/widgets/app_scaffold.dart';
import 'package:bunk_alert/shared/widgets/percentage_slider.dart';

class AddEditSubjectScreen extends StatefulWidget {
  const AddEditSubjectScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  State<AddEditSubjectScreen> createState() => _AddEditSubjectScreenState();
}

class _AddEditSubjectScreenState extends State<AddEditSubjectScreen> {
  final SubjectRepository _subjectRepository = SubjectRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _expectedController = TextEditingController();

  double? _globalTarget;
  double _targetPercent = 75;
  bool _isSaving = false;
  SubjectModel? _subject;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _nameController.addListener(_onFormChanged);
    _expectedController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _expectedController.dispose();
    super.dispose();
  }

  Future<void> _loadDefaults() async {
    final globalTarget =
        await SettingsRepository.instance.getGlobalTargetPercentage();
    final subject = widget.subjectId == null
        ? null
        : await _subjectRepository.getSubjectById(widget.subjectId!);
    if (!mounted) {
      return;
    }
    setState(() {
      _globalTarget = globalTarget;
      _subject = subject;
      _targetPercent = subject?.targetPercentage ?? globalTarget;
      _nameController.text = subject?.name ?? '';
      _expectedController.text =
          subject?.expectedTotalClasses?.toString() ?? '';
    });
  }

  void _onFormChanged() {
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  bool get _isNameValid => _nameController.text.trim().isNotEmpty;

  bool get _canSave => _isNameValid && !_isSaving;

  Future<void> _save() async {
    if (!_canSave) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('Subject name is required.');
      return;
    }

    final subjects = await _subjectRepository.getActiveSubjects();
    final lowerName = name.toLowerCase();
    final duplicate = subjects.any(
      (subject) =>
          subject.uuid != widget.subjectId &&
          subject.name.trim().toLowerCase() == lowerName,
    );
    if (duplicate) {
      _showError('A subject with this name already exists.');
      return;
    }

    final globalTarget = _globalTarget;
    if (globalTarget == null) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();
    final existing = _subject;
    final subjectId = existing?.uuid ?? const Uuid().v4();
    final targetOverride =
        _targetPercent == globalTarget ? null : _targetPercent;
    final expectedTotal = int.tryParse(_expectedController.text.trim());

    final subject = SubjectModel(
      uuid: subjectId,
      name: name,
      colorTagIndex: 0,
      targetPercentage: targetOverride,
      expectedTotalClasses: expectedTotal,
      isArchived: existing?.isArchived ?? false,
      syncStatus: 'pending',
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    await _subjectRepository.upsertSubject(subject);

    if (!mounted) {
      return;
    }
    await FcmService.instance.requestPermissionsIfReady(context);
    setState(() {
      _isSaving = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).brightness == Brightness.dark
        ? AppColors.dark
        : AppColors.light;
    final isEdit = widget.subjectId != null && widget.subjectId!.isNotEmpty;
    final globalTarget = _globalTarget;

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
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium(palette),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    isEdit ? 'Edit Subject' : 'Add Subject',
                    style: AppTextStyles.headingSmall(palette),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _canSave ? _save : null,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          _canSave ? palette.textPrimary : palette.textTertiary,
                    ),
                    child: Text(
                      'Save',
                      style: AppTextStyles.bodyMedium(palette).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: globalTarget == null
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Subject Name',
                            style: AppTextStyles.labelSmall(palette),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _nameController,
                            autofocus: true,
                            textInputAction: TextInputAction.next,
                            style: AppTextStyles.headingLarge(palette),
                            decoration: InputDecoration(
                              hintText: 'Enter subject name',
                              hintStyle:
                                  AppTextStyles.headingLarge(palette).copyWith(
                                color: palette.textTertiary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.cardRadius),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Target Attendance',
                            style: AppTextStyles.headingSmall(palette),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          PercentageSlider(
                            value: _targetPercent,
                            min: 50,
                            max: 100,
                            divisions: 50,
                            onChanged: (value) {
                              setState(() {
                                _targetPercent = value;
                              });
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _targetPercent == globalTarget
                                ? 'Using global default (${globalTarget.round()}%)'
                                : 'Custom target',
                            style: AppTextStyles.caption(palette),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Expected Total Classes',
                            style: AppTextStyles.headingSmall(palette),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextField(
                            controller: _expectedController,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              hintText: 'Optional',
                              border: OutlineInputBorder(
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.cardRadius),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.base,
                                vertical: AppSpacing.md,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Used for exam eligibility calculation',
                            style: AppTextStyles.caption(palette),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
