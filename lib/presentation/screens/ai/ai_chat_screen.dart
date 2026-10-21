import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../application/services/ai_client_service.dart';
import '../../../application/services/ai_data_formatter.dart';
import '../../../data/models/dtos/dtos.dart';
import '../../theme/app_theme.dart';
import '../../navigation/app_router.dart';
import '../../widgets/persona_avatar.dart';
import 'ai_history_screen.dart';
import 'ai_personas.dart';

/// Interactive chat screen with persona guidance, user habit context,
/// real-time LLM replies, and persistent conversation history.
class AiChatScreen extends ConsumerStatefulWidget {
  final AiPersona? persona;
  final PersonaId? personaId;
  final String? conversationId;

  const AiChatScreen({
    super.key,
    this.persona,
    this.personaId,
    this.conversationId,
  });

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  late final TextEditingController _textController;
  late final ScrollController _scrollController;
  late final AiClientService _aiClientService;

  AiPersona? _persona;
  String? _conversationId;
  int _contextWindowDays = 30;
  bool _enableMemory = true;

  final List<AiMessageDto> _messages = [];
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isInputEmpty = true;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _aiClientService = AiClientService();

    _persona = widget.persona ??
        (widget.personaId != null ? AiPersona.fromId(widget.personaId) : null);
    _conversationId = widget.conversationId;

    _textController.addListener(_onTextChanged);
    _initializeChat();
  }

  void _onTextChanged() {
    final empty = _textController.text.trim().isEmpty;
    if (empty != _isInputEmpty) {
      setState(() => _isInputEmpty = empty);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    _scrollController.dispose();
    _aiClientService.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    try {
      final settingsRepo = await ref.read(aiSettingsRepositoryProvider.future);
      final settings = await settingsRepo.getSettings();
      final convRepo = await ref.read(aiConversationRepositoryProvider.future);

      _enableMemory = settings.enableMemory;
      if (_conversationId != null) {
        final existingConv = await convRepo.getConversation(_conversationId!);
        if (existingConv != null) {
          if (existingConv.personaId != null) {
            _persona = AiPersona.fromIdString(existingConv.personaId);
          } else {
            _persona = null;
          }
          _contextWindowDays = existingConv.contextWindowDays;
          final dbMessages = await convRepo.getMessages(_conversationId!);
          _messages.clear();
          _messages.addAll(dbMessages);
        }
      } else {
        _contextWindowDays = settings.contextWindowDays;
        if (_persona == null && settings.selectedPersona != null) {
          _persona = AiPersona.fromIdString(settings.selectedPersona);
        }
      }
    } catch (_) {
      // Graceful fallback to default values
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _toggleMemory() async {
    final newMemory = !_enableMemory;
    setState(() => _enableMemory = newMemory);
    try {
      final settingsRepo = await ref.read(aiSettingsRepositoryProvider.future);
      final current = await settingsRepo.getSettings();
      await settingsRepo.saveSettings(current.copyWith(enableMemory: newMemory));
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _buildHabitContext(int windowDays) async {
    final habitRepo = await ref.read(habitRepositoryProvider.future);
    final entryRepo = await ref.read(habitEntryRepositoryProvider.future);
    final noteRepo = await ref.read(dayNoteRepositoryProvider.future);
    final schedRepo = await ref.read(habitScheduleRepositoryProvider.future);

    final habits = await habitRepo.getAllHabits();
    final today = DateTime.now();
    final todayNormalized = DateTime(today.year, today.month, today.day);
    final fromDate = todayNormalized.subtract(Duration(days: windowDays - 1));

    final entriesByHabitId = <String, List<HabitEntryDto>>{};
    final dayNotesByHabitId = <String, List<DayNoteDto>>{};
    final schedulesByHabitId = <String, HabitScheduleDto>{};

    for (final h in habits) {
      final entries = await entryRepo.getEntriesForHabit(h.id, fromDate, todayNormalized);
      entriesByHabitId[h.id] = entries;

      final notes = await noteRepo.getNotesForHabit(h.id, limit: 30);
      dayNotesByHabitId[h.id] = notes;

      final sched = await schedRepo.getActiveScheduleForHabit(h.id);
      if (sched != null) {
        schedulesByHabitId[h.id] = sched;
      }
    }

    return AiDataFormatter.format(
      habits: habits,
      entriesByHabitId: entriesByHabitId,
      dayNotesByHabitId: dayNotesByHabitId,
      schedulesByHabitId: schedulesByHabitId,
      windowDays: windowDays,
      today: today,
    );
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isGenerating) return;

    _textController.clear();
    setState(() => _isGenerating = true);

    try {
      final settingsRepo = await ref.read(aiSettingsRepositoryProvider.future);
      final settings = await settingsRepo.getSettings();
      final convRepo = await ref.read(aiConversationRepositoryProvider.future);

      // 1. Create conversation and system message if first message
      if (_conversationId == null) {
        final habitDataText = await _buildHabitContext(_contextWindowDays);
        final personaPrompt = _persona?.systemPrompt ??
            'You are a helpful, concise habit-tracking assistant. Use the data below to give personalised observations.';
        final systemContent = '$personaPrompt\n\n$habitDataText';

        final conv = await convRepo.createConversation(
          personaId: _persona?.id.name,
          contextWindowDays: _contextWindowDays,
        );
        _conversationId = conv.id;

        final systemMsg = await convRepo.addMessage(
          conversationId: _conversationId!,
          role: 'system',
          content: systemContent,
        );
        _messages.add(systemMsg);
      }

      // 2. Add user message
      final userMsg = await convRepo.addMessage(
        conversationId: _conversationId!,
        role: 'user',
        content: text,
      );
      setState(() {
        _messages.add(userMsg);
      });
      _scrollToBottom();

      // 3. Call LLM API (send full history if memory enabled, or just system + latest user message if memory disabled)
      final dbMessages = await convRepo.getMessages(_conversationId!);
      final List<AiMessageDto> messagesToSend;
      if (_enableMemory) {
        messagesToSend = dbMessages;
      } else {
        final systemMsgs = dbMessages.where((m) => m.role == 'system').toList();
        final latestUserMsg = dbMessages.where((m) => m.role == 'user').lastOrNull;
        messagesToSend = [
          ...systemMsgs,
          if (latestUserMsg != null) latestUserMsg,
        ];
      }

      final replyText = await _aiClientService.sendMessage(
        apiEndpoint: settings.apiEndpoint,
        apiKey: settings.apiKey,
        messages: messagesToSend,
        modelOverride: settings.modelName,
      );

      // 4. Save assistant response
      final assistantMsg = await convRepo.addMessage(
        conversationId: _conversationId!,
        role: 'assistant',
        content: replyText,
      );

      if (mounted) {
        setState(() {
          _messages.add(assistantMsg);
          _isGenerating = false;
        });
        _scrollToBottom();
      }
    } on AiClientException catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGenerating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to get response: $e'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _confirmClearConversation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Clear conversation?',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        content: const Text(
          'Are you sure you want to clear this conversation? All messages in this session will be permanently deleted.',
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
            child: const Text('Clear', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (_conversationId != null) {
        final convRepo = await ref.read(aiConversationRepositoryProvider.future);
        await convRepo.deleteConversation(_conversationId!);
      }
      setState(() {
        _messages.clear();
        _conversationId = null;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conversation cleared'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _persona?.name ?? 'AI Assistant';

    // Filter out system messages so they are never displayed in the chat UI
    final visibleMessages = _messages.where((m) => m.role != 'system').toList();

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
        title: Row(
          children: [
            PersonaAvatar(
              persona: _persona,
              radius: 16,
              backgroundColor: AppColors.background,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: AppColors.primaryText),
            tooltip: 'Conversation history',
            onPressed: () {
              appNavigateTo(
                context,
                AppRoutes.aiHistory,
                const AiHistoryScreen(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_comment_outlined, color: AppColors.primaryText),
            tooltip: 'New chat',
            onPressed: () {
              setState(() {
                _conversationId = null;
                _messages.clear();
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.primaryText),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'clear') {
                _confirmClearConversation();
              } else if (value == 'toggle_memory') {
                _toggleMemory();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'toggle_memory',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _enableMemory ? Icons.psychology : Icons.psychology_outlined,
                      color: _enableMemory ? AppColors.blue : AppColors.mutedGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      _enableMemory ? 'Disable memory' : 'Enable memory',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 14,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'clear',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Clear conversation',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 14,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.blue))
          : Column(
              children: [
                // Context & Memory Bar
                _buildContextAndMemoryBar(),

                // Message List
                Expanded(
                  child: visibleMessages.isEmpty && !_isGenerating
                      ? _buildEmptyState()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          itemCount: visibleMessages.length + (_isGenerating ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == visibleMessages.length && _isGenerating) {
                              return _buildLoadingBubble();
                            }
                            final msg = visibleMessages[index];
                            return _buildMessageBubble(msg);
                          },
                        ),
                ),

                // Bottom Input Row
                _buildInputRow(),
              ],
            ),
    );
  }

  Widget _buildContextAndMemoryBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.mutedGrey.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 14, color: AppColors.mutedGrey),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Context: last $_contextWindowDays days of your habits',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _toggleMemory,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _enableMemory
                    ? AppColors.blue.withValues(alpha: 0.15)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _enableMemory
                      ? AppColors.blue
                      : AppColors.mutedGrey.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _enableMemory ? Icons.psychology : Icons.psychology_outlined,
                    size: 14,
                    color: _enableMemory ? AppColors.blue : AppColors.mutedGrey,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _enableMemory ? 'Memory ON' : 'Memory OFF',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _enableMemory ? AppColors.blue : AppColors.mutedGrey,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PersonaAvatar(
              persona: _persona,
              radius: 40,
            ),
            const SizedBox(height: 16),
            Text(
              _persona != null ? 'Chat with ${_persona!.name}' : 'Start a Conversation',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryText,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _persona?.tagline ??
                  'Ask questions about your habit progress, streaks, or get daily encouragement.',
              textAlign: TextAlign.center,
              style: const TextStyle(
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

  Widget _buildMessageBubble(AiMessageDto msg) {
    final isUser = msg.role == 'user';

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          decoration: const BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            msg.content,
            style: const TextStyle(
              color: AppColors.controlText,
              fontSize: 14,
              fontFamily: AppTheme.fontPrimary,
            ),
          ),
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            PersonaAvatar(
              persona: _persona,
              radius: 14,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                child: SelectableText(
                  msg.content,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    height: 1.35,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          PersonaAvatar(
            persona: _persona,
            radius: 14,
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
              ),
            ),
            child: const _PulsingDotsIndicator(),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: Color(0xFF2C2C2E))),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 14,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    hintStyle: TextStyle(
                      color: AppColors.mutedGrey,
                      fontSize: 14,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: (_isGenerating || _isInputEmpty) ? null : _sendMessage,
              icon: Icon(
                Icons.send_rounded,
                color: (_isGenerating || _isInputEmpty)
                    ? AppColors.mutedGrey.withValues(alpha: 0.3)
                    : AppColors.orange,
              ),
              tooltip: 'Send',
            ),
          ],
        ),
      ),
    );
  }
}

class _PulsingDotsIndicator extends StatefulWidget {
  const _PulsingDotsIndicator();

  @override
  State<_PulsingDotsIndicator> createState() => _PulsingDotsIndicatorState();
}

class _PulsingDotsIndicatorState extends State<_PulsingDotsIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _calcOpacity(double offset) {
    final value = (_controller.value + offset) % 1.0;
    final wave = 0.5 - 0.5 * cos(value * 2 * pi);
    return 0.3 + 0.7 * wave;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(_calcOpacity(0.0)),
            const SizedBox(width: 5),
            _buildDot(_calcOpacity(0.2)),
            const SizedBox(width: 5),
            _buildDot(_calcOpacity(0.4)),
          ],
        );
      },
    );
  }

  Widget _buildDot(double opacity) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppColors.primaryText.withValues(alpha: opacity.clamp(0.0, 1.0)),
        shape: BoxShape.circle,
      ),
    );
  }
}
