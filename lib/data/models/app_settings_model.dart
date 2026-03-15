class AppSettingsModel {
  const AppSettingsModel({
    required this.targetPercentage,
  });

  final double targetPercentage;

  AppSettingsModel copyWith({double? targetPercentage}) {
    return AppSettingsModel(
      targetPercentage: targetPercentage ?? this.targetPercentage,
    );
  }
}
