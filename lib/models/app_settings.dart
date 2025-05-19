import 'package:hive/hive.dart';

class AppSettings {
  final String? pin;
  final bool isAuthEnabled;
  final bool isAutoBackupEnabled;
  final int autoBackupFrequencyDays;
  final DateTime? lastBackupDate;
  final String? googleDriveToken;
  final bool isDarkModeEnabled;
  final String? lastSyncDate;

  AppSettings({
    this.pin,
    this.isAuthEnabled = false,
    this.isAutoBackupEnabled = false,
    this.autoBackupFrequencyDays = 7,
    this.lastBackupDate,
    this.googleDriveToken,
    this.isDarkModeEnabled = false,
    this.lastSyncDate,
  });

  AppSettings copyWith({
    String? pin,
    bool? isAuthEnabled,
    bool? isAutoBackupEnabled,
    int? autoBackupFrequencyDays,
    DateTime? lastBackupDate,
    String? googleDriveToken,
    bool? isDarkModeEnabled,
    String? lastSyncDate,
  }) {
    return AppSettings(
      pin: pin ?? this.pin,
      isAuthEnabled: isAuthEnabled ?? this.isAuthEnabled,
      isAutoBackupEnabled: isAutoBackupEnabled ?? this.isAutoBackupEnabled,
      autoBackupFrequencyDays: autoBackupFrequencyDays ?? this.autoBackupFrequencyDays,
      lastBackupDate: lastBackupDate ?? this.lastBackupDate,
      googleDriveToken: googleDriveToken ?? this.googleDriveToken,
      isDarkModeEnabled: isDarkModeEnabled ?? this.isDarkModeEnabled,
      lastSyncDate: lastSyncDate ?? this.lastSyncDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pin': pin,
      'isAuthEnabled': isAuthEnabled,
      'isAutoBackupEnabled': isAutoBackupEnabled,
      'autoBackupFrequencyDays': autoBackupFrequencyDays,
      'lastBackupDate': lastBackupDate?.toIso8601String(),
      'googleDriveToken': googleDriveToken,
      'isDarkModeEnabled': isDarkModeEnabled,
      'lastSyncDate': lastSyncDate,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      pin: map['pin'],
      isAuthEnabled: map['isAuthEnabled'] ?? false,
      isAutoBackupEnabled: map['isAutoBackupEnabled'] ?? false,
      autoBackupFrequencyDays: map['autoBackupFrequencyDays'] ?? 7,
      lastBackupDate: map['lastBackupDate'] != null
          ? DateTime.parse(map['lastBackupDate'])
          : null,
      googleDriveToken: map['googleDriveToken'],
      isDarkModeEnabled: map['isDarkModeEnabled'] ?? false,
      lastSyncDate: map['lastSyncDate'],
    );
  }
}

// AppSettingsAdapter removed - using direct serialization instead
