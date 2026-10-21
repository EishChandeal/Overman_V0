import 'package:uuid/uuid.dart';
import '../../objectbox.g.dart';
import '../database/custom_persona_entity.dart';
import '../models/dtos/custom_persona_dto.dart';

/// Repository managing user-defined custom AI personas in ObjectBox.
class CustomPersonaRepository {
  final Store _store;
  late final Box<CustomPersonaEntity> _box;

  CustomPersonaRepository(this._store) {
    _box = _store.box<CustomPersonaEntity>();
  }

  /// Creates a new custom persona and saves it to ObjectBox.
  Future<CustomPersonaDto> createPersona({
    required String name,
    required String tagline,
    required String systemPrompt,
    String? imagePath,
  }) async {
    final id = 'custom_${const Uuid().v4()}';
    final dto = CustomPersonaDto(
      id: id,
      name: name.trim(),
      tagline: tagline.trim(),
      systemPrompt: systemPrompt.trim(),
      imagePath: imagePath?.trim(),
      createdAt: DateTime.now().toUtc(),
    );

    final entity = CustomPersonaEntity.fromDto(dto);
    _box.put(entity);
    return dto;
  }

  /// Updates an existing custom persona.
  Future<void> updatePersona(CustomPersonaDto dto) async {
    final query = _box.query(CustomPersonaEntity_.id.equals(dto.id)).build();
    final existing = query.findFirst();
    query.close();

    final entity = CustomPersonaEntity.fromDto(dto);
    if (existing != null) {
      entity.obId = existing.obId;
    }
    _box.put(entity);
  }

  /// Deletes a custom persona by id.
  Future<void> deletePersona(String id) async {
    final query = _box.query(CustomPersonaEntity_.id.equals(id)).build();
    final ids = query.findIds();
    query.close();

    if (ids.isNotEmpty) {
      _box.removeMany(ids);
    }
  }

  /// Fetches all custom personas ordered by creation time (most recent first).
  Future<List<CustomPersonaDto>> getAllPersonas() async {
    final query = _box
        .query()
        .order(CustomPersonaEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();

    return entities.map((e) => e.toDto()).toList();
  }

  /// Synchronously gets a persona by id.
  CustomPersonaDto? getPersonaById(String id) {
    final query = _box.query(CustomPersonaEntity_.id.equals(id)).build();
    final entity = query.findFirst();
    query.close();

    return entity?.toDto();
  }

  /// Watches all custom personas as a reactive Stream.
  Stream<List<CustomPersonaDto>> watchAllPersonas() {
    return _box
        .query()
        .order(CustomPersonaEntity_.createdAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find().map((e) => e.toDto()).toList());
  }
}
