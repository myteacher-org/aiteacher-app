import 'dart:async';

import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/assignment/data/trial_booking_repository.dart';
import 'package:ai_teacher/ui/courses/course_web_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A trial belongs to the signed-in student, even before a mentor assignment.
class TrialLessonCard extends ConsumerStatefulWidget {
  const TrialLessonCard({super.key});

  @override
  ConsumerState<TrialLessonCard> createState() => _TrialLessonCardState();
}

class _TrialLessonCardState extends ConsumerState<TrialLessonCard>
    with WidgetsBindingObserver {
  Timer? _refreshTimer;
  bool _joining = false;
  int _ticks = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (!mounted) return;
      setState(() {});
      if (++_ticks % 3 == 0) ref.invalidate(trialBookingProvider);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(trialBookingProvider);
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  String _timeLabel(BuildContext context, DateTime startsAt) {
    final local = startsAt.toLocal();
    final labels = MaterialLocalizations.of(context);
    return '${labels.formatMediumDate(local)}, '
        '${labels.formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true)}';
  }

  Future<void> _openLesson(TrialBooking booking) async {
    final now = DateTime.now();
    if (now.isBefore(booking.opensAt)) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.hourglass_top_rounded, size: 42),
          title: const Text('Dars eshigi hali ochilmadi'),
          content: Text(
            'Sinov darsingiz ${_timeLabel(context, booking.startsAt)} da boshlanadi. '
            'Kirish 10 daqiqa oldin ochiladi — tez orada ko‘rishamiz!',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Tushunarli'),
            ),
          ],
        ),
      );
      return;
    }
    if (!now.isBefore(booking.closesAt)) {
      ref.invalidate(trialBookingProvider);
      return;
    }

    setState(() => _joining = true);
    try {
      final url = await ref
          .read(trialBookingRepositoryProvider)
          .getEntryUrl(booking.id);
      if (!mounted) return;
      await context.pushNamed(
        AppRoute.linkWeb.name,
        extra: LinkWebArgs(title: 'Sinov darsi', url: url),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Darsga kirib bo‘lmadi. Qayta urinib ko‘ring.'),
          ),
        );
        ref.invalidate(trialBookingProvider);
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trial = ref.watch(trialBookingProvider);
    if (trial.hasError) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
        child: OutlinedButton.icon(
          onPressed: () => ref.invalidate(trialBookingProvider),
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Sinov darsini tekshirib bo‘lmadi. Qayta urinish'),
        ),
      );
    }
    final booking = trial.valueOrNull;
    if (booking == null) return const SizedBox.shrink();
    final ready = !DateTime.now().isBefore(booking.opensAt);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryDark, AppColors.navy],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryDark.withValues(alpha: 0.20),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'SINOV DARSI BELGILANDI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Demo darsingiz tayyor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              booking.mentorName.isEmpty
                  ? 'Mentoringiz bilan sinov darsi'
                  : '${booking.mentorName} bilan sinov darsi',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.78),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      _timeLabel(context, booking.startsAt),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _joining ? null : () => _openLesson(booking),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                icon: Icon(
                  ready ? Icons.video_call_rounded : Icons.schedule_rounded,
                ),
                label: Text(
                  _joining
                      ? 'Ochilmoqda...'
                      : ready
                      ? 'Darsga kirish'
                      : 'Dars vaqtini ko‘rish',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
