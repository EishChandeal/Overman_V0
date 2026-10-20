import 'dart:core';

class AiSettingsDto {
  final String apiEndpoint;
  final String apiKey;
  final String? selectedPersona;
  final int contextWindowDays;
  final String contextWindowUnit;
  final DateTime updatedAt;

  const AiSettingsDto({
    required this.apiEndpoint,
    required this.apiKey,
    this.selectedPersona,
    this.contextWindowDays = 30,
    this.contextWindowUnit = 'days',
    required this.updatedAt,
  });

  static const Object _sentinel = Object();

  AiSettingsDto copyWith({
    String? apiEndpoint,
    String? apiKey,
    Object? selectedPersona = _sentinel,
    int? contextWindowDays,
    String? contextWindowUnit,
    DateTime? updatedAt,
  }) {
    return AiSettingsDto(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      selectedPersona: selectedPersona == _sentinel
          ? this.selectedPersona
          : selectedPersona as String?,
      contextWindowDays: contextWindowDays ?? this.contextWindowDays,
      contextWindowUnit: contextWindowUnit ?? this.contextWindowUnit,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiEndpoint': apiEndpoint,
      'apiKey': apiKey,
      'selectedPersona': selectedPersona,
      'contextWindowDays': contextWindowDays,
      'contextWindowUnit': contextWindowUnit,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiSettingsDto.fromJson(Map<String, dynamic> json) {
    return AiSettingsDto(
      apiEndpoint: json['apiEndpoint'] as String,
      apiKey: json['apiKey'] as String,
      selectedPersona: json['selectedPersona'] as String?,
      contextWindowDays: (json['contextWindowDays'] as num?)?.toInt() ?? 30,
      contextWindowUnit: (json['contextWindowUnit'] as String?) ?? 'days',
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AiSettingsDto &&
          runtimeType == other.runtimeType &&
          apiEndpoint == other.apiEndpoint &&
          apiKey == other.apiKey &&
          selectedPersona == other.selectedPersona &&
          contextWindowDays == other.contextWindowDays &&
          contextWindowUnit == other.contextWindowUnit &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      apiEndpoint.hashCode ^
      apiKey.hashCode ^
      selectedPersona.hashCode ^
      contextWindowDays.hashCode ^
      contextWindowUnit.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'AiSettingsDto(apiEndpoint: $apiEndpoint, apiKey: $apiKey, selectedPersona: $selectedPersona, contextWindowDays: $contextWindowDays, contextWindowUnit: $contextWindowUnit, updatedAt: $updatedAt)';
  }
}
