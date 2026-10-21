import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../data/database/app_database.dart';
import '../../../data/models/dtos/custom_persona_dto.dart';
import '../../../data/repositories/custom_persona_repository.dart';
import '../../theme/app_theme.dart';
import 'ai_personas.dart';

/// Modal dialog allowing the user to create or edit a custom AI persona character,
/// including their name, tagline, personality system prompt, and custom profile picture.
class CustomPersonaDialog extends StatefulWidget {
  final AiPersona? existingPersona;
  final CustomPersonaRepository? repository;
  final Future<String?> Function()? onPickImage;

  const CustomPersonaDialog({
    super.key,
    this.existingPersona,
    this.repository,
    this.onPickImage,
  });

  @override
  State<CustomPersonaDialog> createState() => _CustomPersonaDialogState();
}

class _CustomPersonaDialogState extends State<CustomPersonaDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _taglineController;
  late final TextEditingController _promptController;

  String? _pickedImagePath;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isEditing => widget.existingPersona != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingPersona?.name ?? '');
    _taglineController =
        TextEditingController(text: widget.existingPersona?.tagline ?? '');
    _promptController =
        TextEditingController(text: widget.existingPersona?.systemPrompt ?? '');
    _pickedImagePath = widget.existingPersona?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _taglineController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _handlePickImage() async {
    if (widget.onPickImage != null) {
      final path = await widget.onPickImage!();
      if (path != null && mounted) {
        setState(() => _pickedImagePath = path);
      }
      return;
    }

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'jfif', 'bmp'],
      );

      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        if (mounted) {
          setState(() {
            _pickedImagePath = result.files.first.path;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select image: $e'),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final tagline = _taglineController.text.trim();
    final prompt = _promptController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter a character name.');
      return;
    }

    if (prompt.isEmpty) {
      setState(() => _errorMessage = 'Please define character personality instructions.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // 1. Copy image to persistent app storage if newly picked
      String? persistentImagePath = _pickedImagePath;
      if (_pickedImagePath != null && File(_pickedImagePath!).existsSync()) {
        try {
          final appDir = await getApplicationDocumentsDirectory();
          final personaDir = Directory(p.join(appDir.path, 'custom_personas'));
          if (!personaDir.existsSync()) {
            personaDir.createSync(recursive: true);
          }
          final ext = p.extension(_pickedImagePath!);
          final targetFile = File(
            p.join(
              personaDir.path,
              'persona_${DateTime.now().millisecondsSinceEpoch}$ext',
            ),
          );
          if (targetFile.path != _pickedImagePath) {
            File(_pickedImagePath!).copySync(targetFile.path);
            persistentImagePath = targetFile.path;
          }
        } catch (_) {
          // If copying fails, fallback to original path
          persistentImagePath = _pickedImagePath;
        }
      }

      // 2. Persist in repository
      final repo = widget.repository ??
          (AppDatabase.isOpen ? CustomPersonaRepository(AppDatabase.instance) : null);

      if (repo == null) {
        throw StateError('Database repository is not available.');
      }

      AiPersona resultPersona;
      if (_isEditing) {
        final existingId = widget.existingPersona!.id.name;
        final dto = CustomPersonaDto(
          id: existingId,
          name: name,
          tagline: tagline,
          systemPrompt: prompt,
          imagePath: persistentImagePath,
          createdAt: DateTime.now().toUtc(),
        );
        await repo.updatePersona(dto);
        resultPersona = dto.toAiPersona();
      } else {
        final createdDto = await repo.createPersona(
          name: name,
          tagline: tagline,
          systemPrompt: prompt,
          imagePath: persistentImagePath,
        );
        resultPersona = createdDto.toAiPersona();
      }

      if (mounted) {
        Navigator.of(context).pop(resultPersona);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save character: $e';
        });
      }
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Character',
          style: TextStyle(
            color: AppColors.primaryText,
            fontWeight: FontWeight.bold,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${widget.existingPersona?.name}"?',
          style: const TextStyle(
            color: AppColors.mutedGrey,
            fontFamily: AppTheme.fontPrimary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final repo = widget.repository ??
            (AppDatabase.isOpen ? CustomPersonaRepository(AppDatabase.instance) : null);
        if (repo != null && widget.existingPersona != null) {
          await repo.deletePersona(widget.existingPersona!.id.name);
        }
        if (mounted) {
          Navigator.of(context).pop('deleted');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _errorMessage = 'Failed to delete character: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isEditing ? 'Edit Character' : 'Create Custom Character',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                        fontFamily: AppTheme.fontPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.mutedGrey),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Profile Picture Selector
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _handlePickImage,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(
                            radius: 44,
                            backgroundColor: AppColors.background,
                            backgroundImage: _pickedImagePath != null &&
                                    File(_pickedImagePath!).existsSync()
                                ? FileImage(File(_pickedImagePath!))
                                : null,
                            child: _pickedImagePath == null ||
                                    !File(_pickedImagePath!).existsSync()
                                ? const Icon(
                                    Icons.add_a_photo_outlined,
                                    size: 32,
                                    color: AppColors.blue,
                                  )
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      key: const Key('custom_persona_pick_picture_btn'),
                      onPressed: _handlePickImage,
                      child: Text(
                        _pickedImagePath != null ? 'Change Profile Picture' : 'Choose Profile Picture',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.blue,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontFamily: AppTheme.fontPrimary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Name Input
              TextField(
                key: const Key('custom_persona_name_input'),
                controller: _nameController,
                maxLength: 50,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Character Name *',
                  labelStyle: const TextStyle(color: AppColors.mutedGrey),
                  hintText: 'e.g. Marcus Aurelius, Goku, Sensei',
                  hintStyle: TextStyle(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppColors.background,
                  counterStyle: const TextStyle(color: AppColors.mutedGrey, fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Tagline Input
              TextField(
                key: const Key('custom_persona_tagline_input'),
                controller: _taglineController,
                maxLength: 100,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                ),
                decoration: InputDecoration(
                  labelText: 'Tagline / Short Title (optional)',
                  labelStyle: const TextStyle(color: AppColors.mutedGrey),
                  hintText: 'e.g. Roman Emperor & Stoic Philosopher',
                  hintStyle: TextStyle(color: AppColors.mutedGrey.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: AppColors.background,
                  counterStyle: const TextStyle(color: AppColors.mutedGrey, fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Personality & Instructions Prompt
              TextField(
                key: const Key('custom_persona_prompt_input'),
                controller: _promptController,
                maxLength: 1500,
                minLines: 4,
                maxLines: 7,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontFamily: AppTheme.fontPrimary,
                  height: 1.4,
                ),
                decoration: InputDecoration(
                  labelText: 'Personality & Behavior Instructions *',
                  labelStyle: const TextStyle(color: AppColors.mutedGrey),
                  hintText:
                      'Describe how this character talks, their tone, attitude, philosophy, and how they should coach you regarding your habits...',
                  hintStyle: TextStyle(
                    color: AppColors.mutedGrey.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  helperText:
                      'This system prompt instructs the AI model on how to think, respond, and guide you.',
                  helperMaxLines: 2,
                  helperStyle: TextStyle(
                    color: AppColors.mutedGrey.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                  counterStyle: const TextStyle(color: AppColors.mutedGrey, fontSize: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Bottom Actions
              Row(
                children: [
                  if (_isEditing)
                    IconButton(
                      key: const Key('custom_persona_delete_btn'),
                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                      tooltip: 'Delete character',
                      onPressed: _isSaving ? null : _handleDelete,
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.mutedGrey)),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton(
                      key: const Key('custom_persona_save_btn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _isSaving ? null : _handleSave,
                      child: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _isEditing ? 'Save Changes' : 'Create Character',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
