// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'streak_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$habitStreakHash() => r'7b00231401655471c643da7ff4415f1a647c2e5f';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [habitStreak].
@ProviderFor(habitStreak)
const habitStreakProvider = HabitStreakFamily();

/// See also [habitStreak].
class HabitStreakFamily extends Family<AsyncValue<StreakResult>> {
  /// See also [habitStreak].
  const HabitStreakFamily();

  /// See also [habitStreak].
  HabitStreakProvider call(String habitId) {
    return HabitStreakProvider(habitId);
  }

  @override
  HabitStreakProvider getProviderOverride(
    covariant HabitStreakProvider provider,
  ) {
    return call(provider.habitId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'habitStreakProvider';
}

/// See also [habitStreak].
class HabitStreakProvider extends AutoDisposeFutureProvider<StreakResult> {
  /// See also [habitStreak].
  HabitStreakProvider(String habitId)
    : this._internal(
        (ref) => habitStreak(ref as HabitStreakRef, habitId),
        from: habitStreakProvider,
        name: r'habitStreakProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitStreakHash,
        dependencies: HabitStreakFamily._dependencies,
        allTransitiveDependencies: HabitStreakFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  HabitStreakProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.habitId,
  }) : super.internal();

  final String habitId;

  @override
  Override overrideWith(
    FutureOr<StreakResult> Function(HabitStreakRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitStreakProvider._internal(
        (ref) => create(ref as HabitStreakRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        habitId: habitId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StreakResult> createElement() {
    return _HabitStreakProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitStreakProvider && other.habitId == habitId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, habitId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HabitStreakRef on AutoDisposeFutureProviderRef<StreakResult> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _HabitStreakProviderElement
    extends AutoDisposeFutureProviderElement<StreakResult>
    with HabitStreakRef {
  _HabitStreakProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitStreakProvider).habitId;
}

String _$habitStatisticsHash() => r'9f9a4a33f686a0079b681b97f2d86ee4a411c9bb';

/// See also [habitStatistics].
@ProviderFor(habitStatistics)
const habitStatisticsProvider = HabitStatisticsFamily();

/// See also [habitStatistics].
class HabitStatisticsFamily extends Family<AsyncValue<StatisticsResult>> {
  /// See also [habitStatistics].
  const HabitStatisticsFamily();

  /// See also [habitStatistics].
  HabitStatisticsProvider call(String habitId, DateRange range) {
    return HabitStatisticsProvider(habitId, range);
  }

  @override
  HabitStatisticsProvider getProviderOverride(
    covariant HabitStatisticsProvider provider,
  ) {
    return call(provider.habitId, provider.range);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'habitStatisticsProvider';
}

/// See also [habitStatistics].
class HabitStatisticsProvider
    extends AutoDisposeFutureProvider<StatisticsResult> {
  /// See also [habitStatistics].
  HabitStatisticsProvider(String habitId, DateRange range)
    : this._internal(
        (ref) => habitStatistics(ref as HabitStatisticsRef, habitId, range),
        from: habitStatisticsProvider,
        name: r'habitStatisticsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitStatisticsHash,
        dependencies: HabitStatisticsFamily._dependencies,
        allTransitiveDependencies:
            HabitStatisticsFamily._allTransitiveDependencies,
        habitId: habitId,
        range: range,
      );

  HabitStatisticsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.habitId,
    required this.range,
  }) : super.internal();

  final String habitId;
  final DateRange range;

  @override
  Override overrideWith(
    FutureOr<StatisticsResult> Function(HabitStatisticsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitStatisticsProvider._internal(
        (ref) => create(ref as HabitStatisticsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        habitId: habitId,
        range: range,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<StatisticsResult> createElement() {
    return _HabitStatisticsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitStatisticsProvider &&
        other.habitId == habitId &&
        other.range == range;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, habitId.hashCode);
    hash = _SystemHash.combine(hash, range.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin HabitStatisticsRef on AutoDisposeFutureProviderRef<StatisticsResult> {
  /// The parameter `habitId` of this provider.
  String get habitId;

  /// The parameter `range` of this provider.
  DateRange get range;
}

class _HabitStatisticsProviderElement
    extends AutoDisposeFutureProviderElement<StatisticsResult>
    with HabitStatisticsRef {
  _HabitStatisticsProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitStatisticsProvider).habitId;
  @override
  DateRange get range => (origin as HabitStatisticsProvider).range;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
