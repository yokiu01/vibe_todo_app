class AppSettings {
  final String key;
  final String value;
  final DateTime updatedAt;

  AppSettings({
    required this.key,
    required this.value,
    required this.updatedAt,
  });

  AppSettings copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      key: map['key'],
      value: map['value'],
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  // Helper methods for common settings
  bool get isThemeDark => value == 'dark';
  bool get isNotificationEnabled => value == 'true';
  bool get isEnergyTrackingEnabled => value == 'true';
  String get language => value;
  String get reviewReminder => value;
}



