import 'dart:async';

import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/lesson_booking/data/lesson_booking_repository.dart';
import 'package:ai_teacher/core/lesson_booking/presentation/student_lessons_controller.dart';
import 'package:ai_teacher/ui/courses/course_web_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// "Sizga sinov darsi belgilandi" — o'quvchining eng yaqin jonli darsi.
/// Havola yuborilmaydi: "Darsga kirish" bosilsa dars ilova ichida ochiladi.
class NextLessonCard extends ConsumerStatefulWidget {
  const NextLessonCard({super.key});

  @override
  ConsumerState<NextLessonCard> createState() => _NextLessonCardState();
}

class _NextLessonCardState extends ConsumerState<NextLessonCard> {
  Timer? _timer;
  bool _opening = false;

  @override
  void initState() {
    super.initState();
    // Qolgan vaqt va tugma holati har 20 soniyada yangilansin
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _join(StudentLesson lesson) async {
    setState(() => _opening = true);
    try {
      final url = await ref
          .read(lessonBookingRepositoryProvider)
          .entryUrl(lesson.id);
      if (!mounted) return;
      await context.pushNamed(
        AppRoute.linkWeb.name,
        extra: LinkWebArgs(
          title: lesson.isTrial ? 'Sinov darsi' : 'Dars',
          url: url,
        ),
      );
      // Darsdan qaytgach ro'yxat yangilansin (o'tilgan dars yo'qoladi)
      ref.invalidate(studentLessonsProvider);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Hozircha darsga kirib bo'lmadi. Dars boshlanishidan 10 daqiqa oldin ochiladi.",
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(nextStudentLessonProvider);
    if (lesson == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final joinable = lesson.isJoinable(now);
    final title = lesson.isTrial
        ? 'Sizga sinov darsi belgilandi'
        : 'Keyingi darsingiz';
    final mentor = (lesson.mentorName ?? '').trim();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.primary],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    lesson.isTrial ? '🎓 SINOV DARSI' : '📚 JONLI DARS',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _qoldi(lesson, now),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                _vaqt(lesson.startsAt, now),
                '${lesson.durationMin} daqiqa',
                if (mentor.isNotEmpty) 'Ustoz: $mentor',
              ].join(' · '),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.88),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: joinable && !_opening ? () => _join(lesson) : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.25),
                  disabledForegroundColor: Colors.white.withValues(alpha: 0.9),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _opening
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        joinable
                            ? 'Darsga kirish'
                            : 'Darsdan 10 daqiqa oldin ochiladi',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _oylar = [
    'yanvar',
    'fevral',
    'mart',
    'aprel',
    'may',
    'iyun',
    'iyul',
    'avgust',
    'sentabr',
    'oktabr',
    'noyabr',
    'dekabr',
  ];

  String _vaqt(DateTime t, DateTime now) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    final bugun = DateTime(now.year, now.month, now.day);
    final kun = DateTime(t.year, t.month, t.day);
    final farq = kun.difference(bugun).inDays;
    final sana = farq == 0
        ? 'Bugun'
        : farq == 1
        ? 'Ertaga'
        : '${t.day}-${_oylar[t.month - 1]}';
    return '$sana, $hh:$mm';
  }

  String _qoldi(StudentLesson l, DateTime now) {
    if (!now.isBefore(l.startsAt)) return 'hozir';
    final d = l.startsAt.difference(now);
    if (d.inMinutes < 60) return '${d.inMinutes + 1} daq qoldi';
    if (d.inHours < 24) return '${d.inHours} soat qoldi';
    return '${d.inDays} kun qoldi';
  }
}
