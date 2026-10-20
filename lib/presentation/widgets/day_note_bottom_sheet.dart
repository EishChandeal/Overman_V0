import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

class DayNoteBottomSheet extends ConsumerStatefulWidget {
  final String habitId;
  final Color? habitColor;
  final DateTime? date;

  const DayNoteBottomSheet({
    super.key,
    required this.habitId,
    this.habitColor,
    this.date,
  });

  @override
  ConsumerState<DayNoteBottomSheet> createState() => _DayNoteBottomSheetState();
}

class _DayNoteBottomSheetState extends ConsumerState<DayNoteBottomSheet> {
  late final TextEditingController _controller;
  DayNoteDto? _existingNote;
  bool _isSaving = false;

  DateTime get _effectiveDate {
    final d = widget.date ?? DateTime.now();
    return DateTime.utc(d.year, d.month, d.day);
  }

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _loadExistingNote();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadExistingNote() async {
    try {
      final repo = await ref.read(dayNoteRepositoryProvider.future);
      final existing = await repo.getNoteForDate(widget.habitId, _effectiveDate);
      if (existing != null && mounted) {
        _existingNote = existing;
        _controller.text = existing.note;
      }
    } catch (_) {
      // Ignored: fallback to empty
    }
  }

  Future<void> _saveNote() async {
    final text = _controller.text.trim();
    setState(() => _isSaving = true);

    try {
      final repo = await ref.read(dayNoteRepositoryProvider.future);
      final targetDateUtc = _effectiveDate;

      if (text.isEmpty && _existingNote != null) {
        // Clear note
        await repo.deleteNote(_existingNote!.id);
      } else if (text.isNotEmpty) {
        final noteDto = DayNoteDto(
          id: _existingNote?.id ?? const Uuid().v4(),
          habitId: widget.habitId,
          date: targetDateUtc,
          note: text,
          createdAt: _existingNote?.createdAt ?? DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await repo.upsertNote(noteDto);
      }

      ref.invalidate(habitDayNotesProvider(widget.habitId));

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note saved for ${DateFormat('E, d MMM').format(_effectiveDate)}'),
            duration: const Duration(seconds: 2),
            backgroundColor: AppColors.surface,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save note: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('E, d MMM').format(_effectiveDate);
    final accentColor = widget.habitColor ?? AppColors.orange;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.note_alt_outlined,
                      color: accentColor,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Note for $todayFormatted',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryText,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.mutedGrey),
                onPressed: () => Navigator.of(context).pop(),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: false,
            minLines: 4,
            maxLines: 10,
            style: const TextStyle(
              color: AppColors.primaryText,
              fontSize: 15,
              fontFamily: AppTheme.fontPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'How did this habit go today? How were you feeling?',
              hintStyle: const TextStyle(
                color: AppColors.mutedGrey,
                fontFamily: AppTheme.fontPrimary,
              ),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: AppColors.mutedGrey,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: AppColors.controlText,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isSaving ? 'Saving...' : 'Save',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: AppTheme.fontPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
