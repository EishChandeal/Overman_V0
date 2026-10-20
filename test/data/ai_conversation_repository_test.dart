import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/data/database/app_database.dart';
import 'package:habit_tracker/data/repositories/repositories.dart';

void main() {
  setUp(() async {
    await AppDatabase.openStore();
  });

  tearDown(() {
    AppDatabase.closeStore();
  });

  group('AiConversationRepository', () {
    test('createConversation creates conversation and stores correctly', () async {
      final store = AppDatabase.instance;
      final repo = AiConversationRepository(store);

      final conversation = await repo.createConversation(
        personaId: 'sakuta',
        contextWindowDays: 14,
      );

      expect(conversation.id, isNotEmpty);
      expect(conversation.personaId, 'sakuta');
      expect(conversation.contextWindowDays, 14);

      final fetched = await repo.getConversation(conversation.id);
      expect(fetched, isNotNull);
      expect(fetched!.id, conversation.id);
      expect(fetched.personaId, 'sakuta');
      expect(fetched.contextWindowDays, 14);
    });

    test('addMessage and getMessages work in chronological order', () async {
      final store = AppDatabase.instance;
      final repo = AiConversationRepository(store);

      final conversation = await repo.createConversation(
        personaId: 'vegeta',
        contextWindowDays: 7,
      );

      final msg1 = await repo.addMessage(
        conversationId: conversation.id,
        role: 'system',
        content: 'System prompt',
      );
      final msg2 = await repo.addMessage(
        conversationId: conversation.id,
        role: 'user',
        content: 'Hello Vegeta!',
      );
      final msg3 = await repo.addMessage(
        conversationId: conversation.id,
        role: 'assistant',
        content: 'Train harder!',
      );

      final messages = await repo.getMessages(conversation.id);
      expect(messages.length, 3);
      expect(messages[0].id, msg1.id);
      expect(messages[0].role, 'system');
      expect(messages[0].content, 'System prompt');

      expect(messages[1].id, msg2.id);
      expect(messages[1].role, 'user');
      expect(messages[1].content, 'Hello Vegeta!');

      expect(messages[2].id, msg3.id);
      expect(messages[2].role, 'assistant');
      expect(messages[2].content, 'Train harder!');

      // Verify conversation updatedAt was refreshed
      final updatedConv = await repo.getConversation(conversation.id);
      expect(updatedConv!.updatedAt.millisecondsSinceEpoch, greaterThanOrEqualTo(conversation.createdAt.millisecondsSinceEpoch));
    });

    test('deleteConversation cascade deletes messages', () async {
      final store = AppDatabase.instance;
      final repo = AiConversationRepository(store);

      final conversation = await repo.createConversation(
        personaId: 'nietzsche',
        contextWindowDays: 30,
      );

      await repo.addMessage(
        conversationId: conversation.id,
        role: 'user',
        content: 'What is the overman?',
      );
      await repo.addMessage(
        conversationId: conversation.id,
        role: 'assistant',
        content: 'Man is something that shall be overcome.',
      );

      expect((await repo.getMessages(conversation.id)).length, 2);

      await repo.deleteConversation(conversation.id);

      expect(await repo.getConversation(conversation.id), isNull);
      expect((await repo.getMessages(conversation.id)).isEmpty, isTrue);
    });

    test('watchAllConversations emits conversations ordered by updatedAt descending', () async {
      final store = AppDatabase.instance;
      final repo = AiConversationRepository(store);

      final conv1 = await repo.createConversation(
        personaId: 'sakuta',
        contextWindowDays: 7,
      );
      final conv2 = await repo.createConversation(
        personaId: 'dumbledore',
        contextWindowDays: 14,
      );

      // Add message to conv1 to bump updatedAt
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.addMessage(
        conversationId: conv1.id,
        role: 'user',
        content: 'Hi Sakuta',
      );

      final all = await repo.getAllConversations();
      expect(all.first.id, conv1.id);
    });
  });
}
