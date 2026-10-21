import 'dart:core';

class AiSettingsDto {
  final String apiEndpoint;
  final String apiKey;
  final String? modelName;
  final String? selectedPersona;
  final int contextWindowDays;
  final String contextWindowUnit;
  final bool enableMemory;
  final DateTime updatedAt;

  const AiSettingsDto({
    required this.apiEndpoint,
    required this.apiKey,
    this.modelName,
    this.selectedPersona,
    this.contextWindowDays = 30,
    this.contextWindowUnit = 'days',
    this.enableMemory = true,
    required this.updatedAt,
  });

  static const Object _sentinel = Object();

  AiSettingsDto copyWith({
    String? apiEndpoint,
    String? apiKey,
    Object? modelName = _sentinel,
    Object? selectedPersona = _sentinel,
    int? contextWindowDays,
    String? contextWindowUnit,
    bool? enableMemory,
    DateTime? updatedAt,
  }) {
    return AiSettingsDto(
      apiEndpoint: apiEndpoint ?? this.apiEndpoint,
      apiKey: apiKey ?? this.apiKey,
      modelName: modelName == _sentinel ? this.modelName : modelName as String?,
      selectedPersona: selectedPersona == _sentinel
          ? this.selectedPersona
          : selectedPersona as String?,
      contextWindowDays: contextWindowDays ?? this.contextWindowDays,
      contextWindowUnit: contextWindowUnit ?? this.contextWindowUnit,
      enableMemory: enableMemory ?? this.enableMemory,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'apiEndpoint': apiEndpoint,
      'apiKey': apiKey,
      'modelName': modelName,
      'selectedPersona': selectedPersona,
      'contextWindowDays': contextWindowDays,
      'contextWindowUnit': contextWindowUnit,
      'enableMemory': enableMemory,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AiSettingsDto.fromJson(Map<String, dynamic> json) {
    return AiSettingsDto(
      apiEndpoint: json['apiEndpoint'] as String,
      apiKey: json['apiKey'] as String,
      modelName: json['modelName'] as String?,
      selectedPersona: json['selectedPersona'] as String?,
      contextWindowDays: (json['contextWindowDays'] as num?)?.toInt() ?? 30,
      contextWindowUnit: (json['contextWindowUnit'] as String?) ?? 'days',
      enableMemory: (json['enableMemory'] as bool?) ?? true,
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
          modelName == other.modelName &&
          selectedPersona == other.selectedPersona &&
          contextWindowDays == other.contextWindowDays &&
          contextWindowUnit == other.contextWindowUnit &&
          enableMemory == other.enableMemory &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      apiEndpoint.hashCode ^
      apiKey.hashCode ^
      modelName.hashCode ^
      selectedPersona.hashCode ^
      contextWindowDays.hashCode ^
      contextWindowUnit.hashCode ^
      enableMemory.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() {
    return 'AiSettingsDto(apiEndpoint: $apiEndpoint, apiKey: $apiKey, modelName: $modelName, selectedPersona: $selectedPersona, contextWindowDays: $contextWindowDays, contextWindowUnit: $contextWindowUnit, enableMemory: $enableMemory, updatedAt: $updatedAt)';
  }
}
