class Location {
  final String id;
  final String name;
  final String wifiSSID;
  final String? wifiBSSID;
  final DateTime createdAt;
  final DateTime updatedAt;

  Location({
    required this.id,
    required this.name,
    required this.wifiSSID,
    this.wifiBSSID,
    required this.createdAt,
    required this.updatedAt,
  });

  Location copyWith({
    String? id,
    String? name,
    String? wifiSSID,
    String? wifiBSSID,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      name: name ?? this.name,
      wifiSSID: wifiSSID ?? this.wifiSSID,
      wifiBSSID: wifiBSSID ?? this.wifiBSSID,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'wifi_ssid': wifiSSID,
      'wifi_bssid': wifiBSSID,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'],
      name: map['name'],
      wifiSSID: map['wifi_ssid'],
      wifiBSSID: map['wifi_bssid'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  @override
  String toString() {
    return 'Location(id: $id, name: $name, wifiSSID: $wifiSSID, wifiBSSID: $wifiBSSID)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Location && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}









