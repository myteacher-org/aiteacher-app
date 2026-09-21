import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/timetable/data/timetable_dtos.dart';
import 'package:ai_teacher/core/timetable/presentation/timetable_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Reached two ways: with a [mentor] passed via typed `extra` (a
/// new/unmatched student browsing mentors for the first time), or with no
/// extra at all — the already-matched "book next lesson with my mentor"
/// path, which supplies the mentor id directly.
class SlotPickerScreen extends ConsumerWidget {
  const SlotPickerScreen({super.key, required this.mentor});

  final BookableMentor mentor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slotsAsync = ref.watch(mentorSlotsProvider(mentor.mentorId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(mentor: mentor, onBack: () => Navigator.of(context).pop()),
            Expanded(
              child: slotsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _ErrorState(
                  onRetry: () =>
                      ref.invalidate(mentorSlotsProvider(mentor.mentorId)),
                ),
                data: (slots) => slots.isEmpty
                    ? const _EmptyState()
                    : _SlotList(mentor: mentor, slots: slots),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.mentor, required this.onBack});

  final BookableMentor mentor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 20, 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mentor.fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0A1628),
                  ),
                ),
                const Text(
                  'Vaqtni tanlang',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlotList extends StatelessWidget {
  const _SlotList({required this.mentor, required this.slots});

  final BookableMentor mentor;
  final List<BookableSlot> slots;

  @override
  Widget build(BuildContext context) {
    final byDay = <DateTime, List<BookableSlot>>{};
    for (final slot in slots) {
      final local = slot.startsAt.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      (byDay[day] ??= []).add(slot);
    }
    final days = byDay.keys.toList()..sort();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        for (final day in days) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
            child: Text(
              _dayLabel(day),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final slot in byDay[day]!)
                _TimeChip(
                  slot: slot,
                  onTap: () => context.pushNamed(
                    AppRoute.bookingConfirm.name,
                    extra: BookingSelection(mentor: mentor, slot: slot),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  String _dayLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    if (day == today) return 'Bugun';
    if (day == tomorrow) return 'Ertaga';
    return '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.slot, required this.onTap});

  final BookableSlot slot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final local = slot.startsAt.toLocal();
    final label =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Bu mentorning hozircha bo'sh vaqti yo'q",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Vaqtlarni yuklab bo'lmadi",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: const Text('Qayta urinish')),
        ],
      ),
    );
  }
}

/// Carries both the chosen mentor and slot into [AppRoute.bookingConfirm]
/// via typed `extra`.
class BookingSelection {
  const BookingSelection({required this.mentor, required this.slot});

  final BookableMentor mentor;
  final BookableSlot slot;
}
