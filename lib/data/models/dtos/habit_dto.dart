import 'dart:core';
import '../../../domain/enums/enums.dart';

// 5. Defines the pure Dart HabitDto data structure that the UI displays.
class HabitDto {
  final String id;
  final String name;
  final HabitType type;
  final String? unit;
  final double? targetValue;
  // Should I add ScheduleType here?
  final String colorHex;
  final String iconName;
  final String? description;
  final bool isOneTime;
  final DateTime? completedAt;
  final DateTime createdAt;
  final bool isArchived;

  const HabitDto({
    required this.id,
    required this.name,
    required this.type,
    this.unit,
    this.targetValue,
    required this.colorHex,
    required this.iconName,
    this.description,
    this.isOneTime = false,
    this.completedAt,
    required this.createdAt,
    required this.isArchived,
  });

  static const Object _sentinel = Object();

  HabitDto copyWith({
    String? id,
    String? name,
    HabitType? type,
    Object? unit = _sentinel,
    Object? targetValue = _sentinel,
    String? colorHex,
    String? iconName,
    Object? description = _sentinel,
    bool? isOneTime,
    Object? completedAt = _sentinel,
    DateTime? createdAt,
    bool? isArchived,
  }) {
    return HabitDto(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit == _sentinel ? this.unit : unit as String?,
      targetValue: targetValue == _sentinel
          ? this.targetValue
          : targetValue as double?,
      colorHex: colorHex ?? this.colorHex,
      iconName: iconName ?? this.iconName,
      description: description == _sentinel
          ? this.description
          : description as String?,
      isOneTime: isOneTime ?? this.isOneTime,
      completedAt: completedAt == _sentinel
          ? this.completedAt
          : completedAt as DateTime?,
      createdAt: createdAt ?? this.createdAt,
      isArchived: isArchived ?? this.isArchived,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'unit': unit,
      'targetValue': targetValue,
      'colorHex': colorHex,
      'iconName': iconName,
      'description': description,
      'isOneTime': isOneTime,
      'completedAt': completedAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isArchived': isArchived,
    };
  }

  factory HabitDto.fromJson(Map<String, dynamic> json) {
    return HabitDto(
      id: json['id'] as String,
      name: json['name'] as String,
      type: HabitType.fromString(json['type'] as String),
      unit: json['unit'] as String?,
      targetValue: (json['targetValue'] as num?)?.toDouble(),
      colorHex: json['colorHex'] as String,
      iconName: json['iconName'] as String,
      description: json['description'] as String?,
      isOneTime: json['isOneTime'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isArchived: json['isArchived'] as bool,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HabitDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          unit == other.unit &&
          targetValue == other.targetValue &&
          colorHex == other.colorHex &&
          iconName == other.iconName &&
          description == other.description &&
          isOneTime == other.isOneTime &&
          completedAt == other.completedAt &&
          createdAt == other.createdAt &&
          isArchived == other.isArchived;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      unit.hashCode ^
      targetValue.hashCode ^
      colorHex.hashCode ^
      iconName.hashCode ^
      description.hashCode ^
      isOneTime.hashCode ^
      completedAt.hashCode ^
      createdAt.hashCode ^
      isArchived.hashCode;

  @override
  String toString() {
    return 'HabitDto(id: $id, name: $name, type: $type, unit: $unit, targetValue: $targetValue, colorHex: $colorHex, iconName: $iconName, description: $description, isOneTime: $isOneTime, completedAt: $completedAt, createdAt: $createdAt, isArchived: $isArchived)';
  }
}
