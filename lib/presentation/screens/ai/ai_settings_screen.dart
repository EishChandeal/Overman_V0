import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../application/providers/providers.dart';
import '../../../data/repositories/custom_persona_repository.dart';
import '../../navigation/app_router.dart';
import '../../theme/app_theme.dart';
import 'ai_chat_screen.dart';
import 'ai_history_screen.dart';
import 'ai_personas.dart';
import '../../widgets/persona_avatar.dart';
import 'custom_persona_dialog.dart';

class AiSettingsScreen extends ConsumerStatefulWidget {
  const AiSettingsScreen({super.key});

  @override
  ConsumerState<AiSettingsScreen> createState() => _AiSettingsScreenState();
}

class _AiSettingsScreenState extends ConsumerState<AiSettingsScreen> {
  late final TextEditingController _endpointController;
  late final TextEditingController _keyController;
  late final TextEditingController _modelController;
  bool _obscureKey = true;
  double _contextWindowDays = 30.0;
  bool _enableMemory = true;
  String? _selectedPersona;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _endpointController = TextEditingController();
    _keyController = TextEditingController();
    _modelController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _endpointController.dispose();
    _keyController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final repo = await ref.read(aiSettingsRepositoryProvider.future);
      final settings = await repo.getSettings();
      if (mounted) {
        setState(() {
          _endpointController.text = settings.apiEndpoint;
          _keyController.text = settings.apiKey;
          _modelController.text = settings.modelName ?? '';
          _contextWindowDays = settings.contextWindowDays.toDouble().clamp(1.0, 90.0);
          _enableMemory = settings.enableMemory;
          _selectedPersona = settings.selectedPersona;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings({bool showToast = true}) async {
    try {
      final repo = await ref.read(aiSettingsRepositoryProvider.future);
      final current = await repo.getSettings();
      final updated = current.copyWith(
        apiEndpoint: _endpointController.text.trim(),
        apiKey: _keyController.text.trim(),
        modelName: _modelController.text.trim().isEmpty ? null : _modelController.text.trim(),
        selectedPersona: _selectedPersona,
        contextWindowDays: _contextWindowDays.round(),
        enableMemory: _enableMemory,
        updatedAt: DateTime.now().toUtc(),
      );
      await repo.saveSettings(updated);

      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppColors.surface,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (showToast && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  String _formatWindowLabel(int days) {
    if (days < 14) {
      return '$days ${days == 1 ? "day" : "days"}';
    } else if (days <= 60) {
      final weeks = (days / 7).round();
      return '$weeks ${weeks == 1 ? "week" : "weeks"}';
    } else {
      return 'All available';
    }
  }

  AiPersona? _resolveSelectedPersona(List<AiPersona> personas) {
    if (_selectedPersona == null) return null;
    return personas.where((p) => p.id.name == _selectedPersona).firstOrNull ??
        AiPersona.fromIdString(_selectedPersona);
  }

  Future<void> _openCustomPersonaDialog({AiPersona? persona}) async {
    CustomPersonaRepository? repo;
    try {
      repo = await ref.read(customPersonaRepositoryProvider.future);
    } catch (_) {}

    if (!mounted) return;
    final result = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => CustomPersonaDialog(
        existingPersona: persona,
        repository: repo,
      ),
    );

    if (result is AiPersona) {
      setState(() {
        _selectedPersona = result.id.name;
      });
      await _saveSettings(showToast: false);
    } else if (result == 'deleted') {
      if (persona != null && _selectedPersona == persona.id.name) {
        setState(() {
          _selectedPersona = null;
        });
        await _saveSettings(showToast: false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.blue),
        ),
      );
    }

    final hasCredentials = _endpointController.text.trim().isNotEmpty &&
        _keyController.text.trim().isNotEmpty;
    final conversationsAsync = ref.watch(aiConversationsProvider);
    final recentConv = conversationsAsync.value?.firstOrNull;
    final allPersonas = ref.watch(allPersonasProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
        title: const Text(
          'AI Assistant',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryText,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // 1. API CONFIGURATION
            _buildSectionHeader('API CONFIGURATION'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _endpointController,
                    keyboardType: TextInputType.url,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'API Endpoint',
                      labelStyle: const TextStyle(color: AppColors.mutedGrey),
                      hintText: 'https://generativelanguage.googleapis.com/v1beta',
                      hintStyle: TextStyle(
                        color: AppColors.mutedGrey.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: const TextStyle(color: AppColors.mutedGrey),
                      hintText: 'Your API key',
                      hintStyle: TextStyle(
                        color: AppColors.mutedGrey.withValues(alpha: 0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureKey ? Icons.visibility_off : Icons.visibility,
                          color: AppColors.mutedGrey,
                        ),
                        onPressed: () {
                          setState(() => _obscureKey = !_obscureKey);
                        },
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _modelController,
                    style: const TextStyle(
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Model Name (optional)',
                      labelStyle: const TextStyle(color: AppColors.mutedGrey),
                      hintText: 'e.g. openai/gpt-oss-120b, gpt-4o-mini',
                      hintStyle: TextStyle(
                        color: AppColors.mutedGrey.withValues(alpha: 0.5),
                      ),
                      helperText: 'Leave empty to auto-select best default for provider',
                      helperStyle: TextStyle(
                        color: AppColors.mutedGrey.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue,
                      foregroundColor: AppColors.controlText,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _saveSettings(showToast: true),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.surface, height: 1),
            const SizedBox(height: 20),

            // 2. CONTEXT WINDOW
            _buildSectionHeader('CONTEXT WINDOW'),
            const SizedBox(height: 4),
            const Text(
              'How much of your habit history to share with the AI',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'History Scope',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryText,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _formatWindowLabel(_contextWindowDays.round()),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.orange,
                            fontFamily: AppTheme.fontPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.orange,
                      inactiveTrackColor: AppColors.background,
                      thumbColor: AppColors.orange,
                      overlayColor: AppColors.orange.withValues(alpha: 0.2),
                      trackHeight: 6,
                    ),
                    child: Slider(
                      value: _contextWindowDays,
                      min: 1.0,
                      max: 90.0,
                      divisions: 89,
                      onChanged: (val) {
                        setState(() => _contextWindowDays = val);
                      },
                      onChangeEnd: (val) {
                        _saveSettings(showToast: false);
                      },
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '1 day',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedGrey.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '4 weeks',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedGrey.withValues(alpha: 0.6),
                        ),
                      ),
                      Text(
                        '90 days (All)',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.mutedGrey.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.background, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Conversation Memory',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _enableMemory
                                  ? 'Include past messages for chat memory'
                                  : 'Memory off (saves API tokens)',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mutedGrey,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _enableMemory,
                        activeThumbColor: AppColors.blue,
                        activeTrackColor: AppColors.blue.withValues(alpha: 0.5),
                        onChanged: (val) {
                          setState(() => _enableMemory = val);
                          _saveSettings(showToast: false);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Divider(color: AppColors.surface, height: 1),
            const SizedBox(height: 20),

            // 3. PERSONA SELECTION
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader('PERSONA'),
                TextButton.icon(
                  key: const Key('add_custom_persona_btn'),
                  onPressed: () => _openCustomPersonaDialog(),
                  icon: const Icon(Icons.add, size: 16, color: AppColors.orange),
                  label: const Text(
                    'Add Custom',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose a character to guide your conversation, or create your own custom personality',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: allPersonas.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemBuilder: (context, index) {
                if (index == allPersonas.length) {
                  // The "Add Custom" tile at the end of the grid
                  return Material(
                    color: AppColors.surface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      key: const Key('create_character_tile'),
                      onTap: () => _openCustomPersonaDialog(),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.orange.withValues(alpha: 0.15),
                              child: const Icon(
                                Icons.add,
                                color: AppColors.orange,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Custom Persona',
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                                fontFamily: AppTheme.fontPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Define character & prompt',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
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

                final persona = allPersonas[index];
                final isSelected = _selectedPersona == persona.id.name;

                return Material(
                  color: isSelected
                      ? AppColors.surface
                      : AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    key: Key('persona_card_${persona.id.name}'),
                    onTap: () {
                      setState(() {
                        if (_selectedPersona == persona.id.name) {
                          _selectedPersona = null;
                        } else {
                          _selectedPersona = persona.id.name;
                        }
                      });
                      _saveSettings(showToast: false);
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.orange
                              : Colors.transparent,
                          width: isSelected ? 2.5 : 1.0,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                PersonaAvatar(
                                  persona: persona,
                                  radius: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  persona.name,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryText,
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  persona.tagline,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.mutedGrey,
                                    fontStyle: FontStyle.italic,
                                    fontFamily: AppTheme.fontPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (persona.isCustom)
                            Positioned(
                              top: -4,
                              right: -4,
                              child: IconButton(
                                key: Key('edit_persona_${persona.id.name}'),
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AppColors.orange,
                                ),
                                tooltip: 'Edit character',
                                onPressed: () => _openCustomPersonaDialog(persona: persona),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 4. PREVIOUS CONVERSATIONS (Browse history)
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.history,
                  color: AppColors.blue,
                ),
                title: const Text(
                  'Previous Conversations',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryText,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
                subtitle: Text(
                  conversationsAsync.value != null && conversationsAsync.value!.isNotEmpty
                      ? '${conversationsAsync.value!.length} past session${conversationsAsync.value!.length == 1 ? "" : "s"}'
                      : 'Browse past chat sessions',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.mutedGrey,
                ),
                onTap: () {
                  appNavigateTo(
                    context,
                    AppRoutes.aiHistory,
                    const AiHistoryScreen(),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // 5. START / CONTINUE CHAT ACTION
            if (recentConv != null) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.chat_bubble_outline, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCredentials
                      ? AppColors.blue
                      : AppColors.surface.withValues(alpha: 0.5),
                  foregroundColor: hasCredentials
                      ? AppColors.controlText
                      : AppColors.mutedGrey,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: hasCredentials ? 2 : 0,
                ),
                onPressed: hasCredentials
                    ? () async {
                        await _saveSettings(showToast: false);
                        if (!context.mounted) return;
                        appNavigateTo(
                          context,
                          AppRoutes.aiChat,
                          AiChatScreen(conversationId: recentConv.id),
                        );
                      }
                    : null,
                label: const Text(
                  'Continue Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.add, size: 18),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.blue,
                  side: const BorderSide(color: AppColors.blue, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: hasCredentials
                    ? () async {
                        await _saveSettings(showToast: false);
                        if (!context.mounted) return;
                        final persona = _resolveSelectedPersona(allPersonas);
                        appNavigateTo(
                          context,
                          AppRoutes.aiChat,
                          AiChatScreen(persona: persona),
                        );
                      }
                    : null,
                label: const Text(
                  'Start New Chat',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ] else ...[
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasCredentials
                      ? AppColors.blue
                      : AppColors.surface.withValues(alpha: 0.5),
                  foregroundColor: hasCredentials
                      ? AppColors.controlText
                      : AppColors.mutedGrey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: hasCredentials ? 2 : 0,
                ),
                onPressed: hasCredentials
                    ? () async {
                        await _saveSettings(showToast: false);
                        if (!context.mounted) return;
                        final persona = _resolveSelectedPersona(allPersonas);
                        appNavigateTo(
                          context,
                          AppRoutes.aiChat,
                          AiChatScreen(persona: persona),
                        );
                      }
                    : null,
                child: Text(
                  'Start Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: hasCredentials
                        ? AppColors.controlText
                        : AppColors.mutedGrey.withValues(alpha: 0.6),
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.mutedGrey,
        fontFamily: AppTheme.fontPrimary,
      ),
    );
  }
}
