import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/call/presentation/call_controller.dart';
import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';
import 'package:ai_teacher/core/timetable/domain/call_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A single upcoming (booked) lesson, with a Join button that lights up
/// once inside the call window. Visual family matches [LiveCard]'s
/// gradient-CTA look.
class UpcomingLessonCard extends ConsumerWidget {
  const UpcomingLessonCard({super.key, required this.lesson});

  final UpcomingLesson lesson;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final local = lesson.startsAt.toLocal();
    final dateLabel =
        '${local.day.toString().padLeft(2, '0')}.${local.month.toString().padLeft(2, '0')} · '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    final joinable = isWithinCallWindow(lesson);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.mentor.fullName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: joinable
                        ? AppColors.primaryDark
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          if (joinable)
            FilledButton(
              onPressed: () {
                ref
                    .read(callControllerProvider.notifier)
                    .startCall(lesson.assignmentId);
                context.pushNamed(AppRoute.call.name);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                "Qo'shilish",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
