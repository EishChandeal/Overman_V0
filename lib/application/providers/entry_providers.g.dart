// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entry_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$habitEntriesHash() => r'b165ce0b9e8db2092a60097dde1d6c414265468e';

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

/// See also [habitEntries].
@ProviderFor(habitEntries)
const habitEntriesProvider = HabitEntriesFamily();

/// See also [habitEntries].
class HabitEntriesFamily extends Family<AsyncValue<List<HabitEntryDto>>> {
  /// See also [habitEntries].
  const HabitEntriesFamily();

  /// See also [habitEntries].
  HabitEntriesProvider call(String habitId) {
    return HabitEntriesProvider(habitId);
  }

  @override
  HabitEntriesProvider getProviderOverride(
    covariant HabitEntriesProvider provider,
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
  String? get name => r'habitEntriesProvider';
}

/// See also [habitEntries].
class HabitEntriesProvider
    extends AutoDisposeStreamProvider<List<HabitEntryDto>> {
  /// See also [habitEntries].
  HabitEntriesProvider(String habitId)
    : this._internal(
        (ref) => habitEntries(ref as HabitEntriesRef, habitId),
        from: habitEntriesProvider,
        name: r'habitEntriesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitEntriesHash,
        dependencies: HabitEntriesFamily._dependencies,
        allTransitiveDependencies:
            HabitEntriesFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  HabitEntriesProvider._internal(
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
    Stream<List<HabitEntryDto>> Function(HabitEntriesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitEntriesProvider._internal(
        (ref) => create(ref as HabitEntriesRef),
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
  AutoDisposeStreamProviderElement<List<HabitEntryDto>> createElement() {
    return _HabitEntriesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitEntriesProvider && other.habitId == habitId;
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
mixin HabitEntriesRef on AutoDisposeStreamProviderRef<List<HabitEntryDto>> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _HabitEntriesProviderElement
    extends AutoDisposeStreamProviderElement<List<HabitEntryDto>>
    with HabitEntriesRef {
  _HabitEntriesProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitEntriesProvider).habitId;
}

String _$entriesForDateHash() => r'6c01fb537f0d1002392db132deed4fd994cf2fa0';

/// See also [entriesForDate].
@ProviderFor(entriesForDate)
const entriesForDateProvider = EntriesForDateFamily();

/// See also [entriesForDate].
class EntriesForDateFamily extends Family<AsyncValue<List<HabitEntryDto>>> {
  /// See also [entriesForDate].
  const EntriesForDateFamily();

  /// See also [entriesForDate].
  EntriesForDateProvider call(DateTime date) {
    return EntriesForDateProvider(date);
  }

  @override
  EntriesForDateProvider getProviderOverride(
    covariant EntriesForDateProvider provider,
  ) {
    return call(provider.date);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'entriesForDateProvider';
}

/// See also [entriesForDate].
class EntriesForDateProvider
    extends AutoDisposeFutureProvider<List<HabitEntryDto>> {
  /// See also [entriesForDate].
  EntriesForDateProvider(DateTime date)
    : this._internal(
        (ref) => entriesForDate(ref as EntriesForDateRef, date),
        from: entriesForDateProvider,
        name: r'entriesForDateProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$entriesForDateHash,
        dependencies: EntriesForDateFamily._dependencies,
        allTransitiveDependencies:
            EntriesForDateFamily._allTransitiveDependencies,
        date: date,
      );

  EntriesForDateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final DateTime date;

  @override
  Override overrideWith(
    FutureOr<List<HabitEntryDto>> Function(EntriesForDateRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: EntriesForDateProvider._internal(
        (ref) => create(ref as EntriesForDateRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<HabitEntryDto>> createElement() {
    return _EntriesForDateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is EntriesForDateProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin EntriesForDateRef on AutoDisposeFutureProviderRef<List<HabitEntryDto>> {
  /// The parameter `date` of this provider.
  DateTime get date;
}

class _EntriesForDateProviderElement
    extends AutoDisposeFutureProviderElement<List<HabitEntryDto>>
    with EntriesForDateRef {
  _EntriesForDateProviderElement(super.provider);

  @override
  DateTime get date => (origin as EntriesForDateProvider).date;
}

String _$entryActionsHash() => r'c27b4b64f2fcf926f30b266c3464693b458f3d88';

/// See also [EntryActions].
@ProviderFor(EntryActions)
final entryActionsProvider =
    AutoDisposeAsyncNotifierProvider<EntryActions, void>.internal(
      EntryActions.new,
      name: r'entryActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$entryActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$EntryActions = AutoDisposeAsyncNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
