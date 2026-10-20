// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$habitDayNotesHash() => r'a9149f723a8af227a868772da5a57cc5b8f0deae';

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

/// See also [habitDayNotes].
@ProviderFor(habitDayNotes)
const habitDayNotesProvider = HabitDayNotesFamily();

/// See also [habitDayNotes].
class HabitDayNotesFamily extends Family<AsyncValue<List<DayNoteDto>>> {
  /// See also [habitDayNotes].
  const HabitDayNotesFamily();

  /// See also [habitDayNotes].
  HabitDayNotesProvider call(String habitId) {
    return HabitDayNotesProvider(habitId);
  }

  @override
  HabitDayNotesProvider getProviderOverride(
    covariant HabitDayNotesProvider provider,
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
  String? get name => r'habitDayNotesProvider';
}

/// See also [habitDayNotes].
class HabitDayNotesProvider
    extends AutoDisposeStreamProvider<List<DayNoteDto>> {
  /// See also [habitDayNotes].
  HabitDayNotesProvider(String habitId)
    : this._internal(
        (ref) => habitDayNotes(ref as HabitDayNotesRef, habitId),
        from: habitDayNotesProvider,
        name: r'habitDayNotesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$habitDayNotesHash,
        dependencies: HabitDayNotesFamily._dependencies,
        allTransitiveDependencies:
            HabitDayNotesFamily._allTransitiveDependencies,
        habitId: habitId,
      );

  HabitDayNotesProvider._internal(
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
    Stream<List<DayNoteDto>> Function(HabitDayNotesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: HabitDayNotesProvider._internal(
        (ref) => create(ref as HabitDayNotesRef),
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
  AutoDisposeStreamProviderElement<List<DayNoteDto>> createElement() {
    return _HabitDayNotesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is HabitDayNotesProvider && other.habitId == habitId;
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
mixin HabitDayNotesRef on AutoDisposeStreamProviderRef<List<DayNoteDto>> {
  /// The parameter `habitId` of this provider.
  String get habitId;
}

class _HabitDayNotesProviderElement
    extends AutoDisposeStreamProviderElement<List<DayNoteDto>>
    with HabitDayNotesRef {
  _HabitDayNotesProviderElement(super.provider);

  @override
  String get habitId => (origin as HabitDayNotesProvider).habitId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
