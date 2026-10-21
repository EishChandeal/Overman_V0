import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../application/providers/providers.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../navigation/app_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/persona_avatar.dart';
import 'ai_chat_screen.dart';
import 'ai_personas.dart';

/// Screen displaying past AI conversations with options to browse,
/// resume, or swipe to delete.
class AiHistoryScreen extends ConsumerStatefulWidget {
  const AiHistoryScreen({super.key});

  @override
  ConsumerState<AiHistoryScreen> createState() => _AiHistoryScreenState();
}

class _AiHistoryScreenState extends ConsumerState<AiHistoryScreen> {
  final Set<String> _locallyDeletedIds = {};

  String _formatRelativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.isNegative || difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final m = difference.inMinutes;
      return '${m}m ago';
    } else if (difference.inHours < 24) {
      final h = difference.inHours;
      return '${h}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('d MMM').format(dt);
    }
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete conversation?',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this conversation? All messages will be permanently removed.',
          style: TextStyle(
            color: AppColors.mutedGrey,
            fontSize: 14,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final conversationsAsync = ref.watch(aiConversationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'Previous Conversations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
        error: (err, _) => Center(
          child: Text(
            'Failed to load conversations: $err',
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
        data: (allConversations) {
          final conversations = allConversations
              .where((c) => !_locallyDeletedIds.contains(c.id))
              .toList();

          if (conversations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 56,
                      color: AppColors.mutedGrey.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No conversations yet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Past chat sessions with your AI personas will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedGrey,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversations.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Color(0xFF2C2C2E),
              indent: 72,
            ),
            itemBuilder: (context, index) {
              final conv = conversations[index];
              final persona = AiPersona.fromIdString(conv.personaId);
              final name = persona?.name ?? 'AI Assistant';

              return Dismissible(
                key: ValueKey(conv.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  color: Colors.redAccent,
                  child: const Icon(
                    Icons.delete_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                confirmDismiss: (direction) => _showDeleteConfirmation(context),
                onDismissed: (_) async {
                  setState(() {
                    _locallyDeletedIds.add(conv.id);
                  });
                  final repo = await ref.read(aiConversationRepositoryProvider.future);
                  await repo.deleteConversation(conv.id);
                  ref.invalidate(aiConversationsProvider);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Conversation deleted'),
                        backgroundColor: AppColors.surface,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: PersonaAvatar(
                    persona: persona,
                    radius: 20,
                  ),
                  title: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                  subtitle: FutureBuilder<AiMessageDto?>(
                    future: ref
                        .read(aiConversationRepositoryProvider.future)
                        .then((repo) => repo.getLastMessage(conv.id)),
                    builder: (context, snapshot) {
                      final snippet = snapshot.data?.content ?? 'No messages yet';
                      final preview = snippet.length > 60
                          ? '${snippet.substring(0, 60)}...'
                          : snippet;

                      return Text(
                        preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.mutedGrey,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      );
                    },
                  ),
                  trailing: Text(
                    _formatRelativeTime(conv.updatedAt.toLocal()),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                  onTap: () {
                    appNavigateTo(
                      context,
                      AppRoutes.aiChat,
                      AiChatScreen(
                        conversationId: conv.id,
                        persona: persona,
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
