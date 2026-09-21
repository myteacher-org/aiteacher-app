import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/timetable/presentation/timetable_controller.dart';
import 'package:ai_teacher/ui/lessons/widget/upcoming_lesson_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UpcomingLessonsScreen extends ConsumerWidget {
  const UpcomingLessonsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(upcomingLessonsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Kelgusi darslar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0A1628),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: lessonsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => Center(
                  child: TextButton(
                    onPressed: () => ref.invalidate(upcomingLessonsProvider),
                    child: const Text("Qayta urinish"),
                  ),
                ),
                data: (lessons) => lessons.isEmpty
                    ? const Center(
                        child: Text(
                          "Hali kelgusi dars yo'q",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async =>
                            ref.invalidate(upcomingLessonsProvider),
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: lessons.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) =>
                              UpcomingLessonCard(lesson: lessons[i]),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
