import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import 'ai_personas.dart';

/// Screen for chatting with the AI model using habit data and personas.
/// Implemented fully in PROD-04-C.
class AiChatScreen extends ConsumerWidget {
  final AiPersona? persona;

  const AiChatScreen({super.key, this.persona});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = persona?.name ?? 'AI Assistant';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            if (persona != null) ...[
              CircleAvatar(
                radius: 16,
                backgroundImage: AssetImage(persona!.assetPath),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.smart_toy_outlined,
                size: 64,
                color: AppColors.blue.withValues(alpha: 0.8),
              ),
              const SizedBox(height: 16),
              Text(
                'Ready to chat with $title',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                persona != null
                    ? persona!.tagline
                    : 'Chat with your habit history and get suggestions',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.mutedGrey,
                  fontStyle: FontStyle.italic,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
