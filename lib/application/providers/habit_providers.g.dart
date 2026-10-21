// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habit_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$habitListHash() => r'4ffa210698779878a926ee87a40186ad3d983d2a';

/// See also [habitList].
@ProviderFor(habitList)
final habitListProvider = AutoDisposeStreamProvider<List<HabitDto>>.internal(
  habitList,
  name: r'habitListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$habitListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef HabitListRef = AutoDisposeStreamProviderRef<List<HabitDto>>;
String _$archivedHabitsHash() => r'fb32b7ca11d6925d8d96359a00a143a9def37481';

/// See also [archivedHabits].
@ProviderFor(archivedHabits)
final archivedHabitsProvider =
    AutoDisposeStreamProvider<List<HabitDto>>.internal(
      archivedHabits,
      name: r'archivedHabitsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$archivedHabitsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ArchivedHabitsRef = AutoDisposeStreamProviderRef<List<HabitDto>>;
String _$habitByIdHash() => r'0b9f056778e477fc7509406832a72fe7185faf0f';

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

/// See also [habitById].
@ProviderFor(habitById)
const habitByIdProvider = HabitByIdFamily();

/// See also [habitById].
class HabitByIdFamily extends Family<AsyncValue<HabitDto?>> {
  /// See also [habitById].
  const HabitByIdFamily();

  /// See also [habitById].
  HabitByIdProvider call(String habitId) {
    return HabitByIdProvider(habitId);
  }

  @override
  HabitByIdProvider getProviderOverride(covariant HabitByIdProvider provider) {
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
  String? get name => r'habitByIdProvider';
}

/// See also [habitById].
class HabitByIdProvider extends AutoDisposeFutureProvider<HabitDto?> {
  /// See also [habitById].
  HabitByIdProvider(String habitId)
    : this._internal(
        (ref) => habitById(ref as HabitByIdRef, habitId),
        from: habitByIdProvider,
        name: r'habitByIdProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitByIdHash,
        dependencies: HabitByIdFamily._dependencies,
        allTransitiveDependencies: HabitByIdFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  HabitByIdProvider._internal(
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
    FutureOr<HabitDto?> Function(HabitByIdRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitByIdProvider._internal(
        (ref) => create(ref as HabitByIdRef),
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
  AutoDisposeFutureProviderElement<HabitDto?> createElement() {
    return _HabitByIdProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitByIdProvider && other.habitId == habitId;
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
mixin HabitByIdRef on AutoDisposeFutureProviderRef<HabitDto?> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _HabitByIdProviderElement
    extends AutoDisposeFutureProviderElement<HabitDto?>
    with HabitByIdRef {
  _HabitByIdProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitByIdProvider).habitId;
}

String _$activeScheduleHash() => r'f84305986bc8be4955183248d046c4902491dc97';

/// See also [activeSchedule].
@ProviderFor(activeSchedule)
const activeScheduleProvider = ActiveScheduleFamily();

/// See also [activeSchedule].
class ActiveScheduleFamily extends Family<AsyncValue<HabitScheduleDto?>> {
  /// See also [activeSchedule].
  const ActiveScheduleFamily();

  /// See also [activeSchedule].
  ActiveScheduleProvider call(String habitId) {
    return ActiveScheduleProvider(habitId);
  }

  @override
  ActiveScheduleProvider getProviderOverride(
    covariant ActiveScheduleProvider provider,
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
  String? get name => r'activeScheduleProvider';
}

/// See also [activeSchedule].
class ActiveScheduleProvider
    extends AutoDisposeFutureProvider<HabitScheduleDto?> {
  /// See also [activeSchedule].
  ActiveScheduleProvider(String habitId)
    : this._internal(
        (ref) => activeSchedule(ref as ActiveScheduleRef, habitId),
        from: activeScheduleProvider,
        name: r'activeScheduleProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activeScheduleHash,
        dependencies: ActiveScheduleFamily._dependencies,
        allTransitiveDependencies:
            ActiveScheduleFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  ActiveScheduleProvider._internal(
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
    FutureOr<HabitScheduleDto?> Function(ActiveScheduleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveScheduleProvider._internal(
        (ref) => create(ref as ActiveScheduleRef),
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
  AutoDisposeFutureProviderElement<HabitScheduleDto?> createElement() {
    return _ActiveScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveScheduleProvider && other.habitId == habitId;
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
mixin ActiveScheduleRef on AutoDisposeFutureProviderRef<HabitScheduleDto?> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _ActiveScheduleProviderElement
    extends AutoDisposeFutureProviderElement<HabitScheduleDto?>
    with ActiveScheduleRef {
  _ActiveScheduleProviderElement(super.provider);

  @override
  String get habitId => (origin as ActiveScheduleProvider).habitId;
}

String _$activeLimitHash() => r'53c13cfa997ede1935c815d65b38784cf5229537';

/// See also [activeLimit].
@ProviderFor(activeLimit)
const activeLimitProvider = ActiveLimitFamily();

/// See also [activeLimit].
class ActiveLimitFamily extends Family<AsyncValue<HabitLimitDto?>> {
  /// See also [activeLimit].
  const ActiveLimitFamily();

  /// See also [activeLimit].
  ActiveLimitProvider call(String habitId) {
    return ActiveLimitProvider(habitId);
  }

  @override
  ActiveLimitProvider getProviderOverride(
    covariant ActiveLimitProvider provider,
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
  String? get name => r'activeLimitProvider';
}

/// See also [activeLimit].
class ActiveLimitProvider extends AutoDisposeFutureProvider<HabitLimitDto?> {
  /// See also [activeLimit].
  ActiveLimitProvider(String habitId)
    : this._internal(
        (ref) => activeLimit(ref as ActiveLimitRef, habitId),
        from: activeLimitProvider,
        name: r'activeLimitProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$activeLimitHash,
        dependencies: ActiveLimitFamily._dependencies,
        allTransitiveDependencies: ActiveLimitFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  ActiveLimitProvider._internal(
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
    FutureOr<HabitLimitDto?> Function(ActiveLimitRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ActiveLimitProvider._internal(
        (ref) => create(ref as ActiveLimitRef),
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
  AutoDisposeFutureProviderElement<HabitLimitDto?> createElement() {
    return _ActiveLimitProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveLimitProvider && other.habitId == habitId;
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
mixin ActiveLimitRef on AutoDisposeFutureProviderRef<HabitLimitDto?> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _ActiveLimitProviderElement
    extends AutoDisposeFutureProviderElement<HabitLimitDto?>
    with ActiveLimitRef {
  _ActiveLimitProviderElement(super.provider);

  @override
  String get habitId => (origin as ActiveLimitProvider).habitId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
