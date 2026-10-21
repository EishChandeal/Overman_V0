import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/dtos/dtos.dart';
import 'repository_providers.dart';

part 'ai_conversation_providers.g.dart';

@Riverpod(keepAlive: true)
Stream<List<AiConversationDto>> aiConversations(AiConversationsRef ref) async* {
  final repo = await ref.watch(aiConversationRepositoryProvider.future);
  yield* repo.watchAllConversations();
}
