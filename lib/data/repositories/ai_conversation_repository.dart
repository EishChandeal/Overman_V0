import 'package:uuid/uuid.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/data/database/ai_conversation_entity.dart';
import 'package:habit_tracker/data/database/ai_message_entity.dart';
import 'package:habit_tracker/objectbox.g.dart';

class AiConversationRepository {
  final Store _store;
  late final Box<AiConversationEntity> _conversationBox;
  late final Box<AiMessageEntity> _messageBox;

  AiConversationRepository(this._store) {
    _conversationBox = _store.box<AiConversationEntity>();
    _messageBox = _store.box<AiMessageEntity>();
  }

  Future<AiConversationDto> createConversation({
    String? personaId,
    required int contextWindowDays,
  }) async {
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final entity = AiConversationEntity(
      id: id,
      personaId: personaId,
      contextWindowDays: contextWindowDays,
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    );
    _conversationBox.put(entity);
    return entity.toDto();
  }

  Future<AiConversationDto?> getConversation(String conversationId) async {
    final query = _conversationBox
        .query(AiConversationEntity_.id.equals(conversationId))
        .build();
    final entity = query.findFirst();
    query.close();
    return entity?.toDto();
  }

  Future<List<AiMessageDto>> getMessages(String conversationId) async {
    final query = _messageBox
        .query(AiMessageEntity_.conversationId.equals(conversationId))
        .order(AiMessageEntity_.createdAt)
        .build();
    final messages = query.find().map((e) => e.toDto()).toList();
    query.close();
    return messages;
  }

  Future<AiMessageDto?> getLastMessage(String conversationId) async {
    final query = _messageBox
        .query(AiMessageEntity_.conversationId.equals(conversationId))
        .order(AiMessageEntity_.createdAt, flags: Order.descending)
        .build();
    final entities = query.find();
    query.close();
    final nonSystem = entities.where((e) => e.role != 'system').firstOrNull;
    return nonSystem?.toDto();
  }

  Future<AiMessageDto> addMessage({
    required String conversationId,
    required String role,
    required String content,
  }) async {
    final now = DateTime.now().toUtc();
    final id = const Uuid().v4();
    final entity = AiMessageEntity(
      id: id,
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: now.millisecondsSinceEpoch,
    );
    _messageBox.put(entity);

    // Update conversation updatedAt timestamp
    final convQuery = _conversationBox
        .query(AiConversationEntity_.id.equals(conversationId))
        .build();
    final convEntity = convQuery.findFirst();
    convQuery.close();
    if (convEntity != null) {
      convEntity.updatedAt = now.millisecondsSinceEpoch;
      _conversationBox.put(convEntity);
    }

    return entity.toDto();
  }

  Future<void> deleteConversation(String conversationId) async {
    // Cascade delete related messages
    final msgQuery = _messageBox
        .query(AiMessageEntity_.conversationId.equals(conversationId))
        .build();
    final msgIds = msgQuery.findIds();
    msgQuery.close();
    if (msgIds.isNotEmpty) {
      _messageBox.removeMany(msgIds);
    }

    // Delete conversation entity
    final convQuery = _conversationBox
        .query(AiConversationEntity_.id.equals(conversationId))
        .build();
    final convIds = convQuery.findIds();
    convQuery.close();
    if (convIds.isNotEmpty) {
      _conversationBox.removeMany(convIds);
    }
  }

  Stream<List<AiConversationDto>> watchAllConversations() {
    return _conversationBox
        .query()
        .order(AiConversationEntity_.updatedAt, flags: Order.descending)
        .watch(triggerImmediately: true)
        .map((query) => query.find().map((e) => e.toDto()).toList());
  }

  Future<List<AiConversationDto>> getAllConversations() async {
    final query = _conversationBox
        .query()
        .order(AiConversationEntity_.updatedAt, flags: Order.descending)
        .build();
    final results = query.find().map((e) => e.toDto()).toList();
    query.close();
    return results;
  }
}
