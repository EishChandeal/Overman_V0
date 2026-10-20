import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:habit_tracker/application/providers/providers.dart';
import 'package:habit_tracker/presentation/theme/app_theme.dart';

class NotesPanel extends ConsumerWidget {
  final String habitId;
  final Color? habitColor;

  const NotesPanel({
    super.key,
    required this.habitId,
    this.habitColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesAsync = ref.watch(habitDayNotesProvider(habitId));
    final accentColor = habitColor ?? AppColors.orange;

    return notesAsync.when(
      data: (notes) {
        if (notes.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No notes yet. Hold the card to add one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedGrey,
                  fontSize: 13,
                  fontFamily: AppTheme.fontPrimary,
                ),
              ),
            ),
          );
        }

        // Most recent 7 notes, newest at top, oldest at bottom
        return Container(
          constraints: const BoxConstraints(maxHeight: 260),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(12),
            itemCount: notes.length,
            separatorBuilder: (_, __) =>
                const Divider(color: AppColors.surface, height: 16),
            itemBuilder: (context, index) {
              final note = notes[index];
              final dateFormatted =
                  DateFormat('EEE, d MMM yyyy').format(note.date.toLocal());

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: accentColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateFormatted,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: accentColor,
                          fontFamily: AppTheme.fontPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.note,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.primaryText,
                      fontFamily: AppTheme.fontPrimary,
                      height: 1.35,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Text(
            'Failed to load notes: $err',
            style: const TextStyle(color: AppColors.mutedGrey, fontSize: 13),
          ),
        ),
      ),
    );
  }
}
