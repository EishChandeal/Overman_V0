class AppSessionDto {
  final String id;
  final DateTime date;
  final DateTime createdAt;

  const AppSessionDto({
    required this.id,
    required this.date,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSessionDto &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          createdAt == other.createdAt;

  @override
  int get hashCode => id.hashCode ^ date.hashCode ^ createdAt.hashCode;
}
