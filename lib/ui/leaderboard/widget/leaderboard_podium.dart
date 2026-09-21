import 'dart:math' as math;

import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_avatar.dart';
import 'package:flutter/material.dart';

/// Top-3 podium. Renders whatever subset of rank 1–3 is actually present
/// (a small cohort may not have all three) — #2 left, #1 center and
/// dominant, #3 right. Columns are fixed-width (not stretched to fill the
/// row) so the risers stay proportional to the avatars regardless of
/// screen width.
class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.entries,
    required this.entrance,
    required this.pulse,
  });

  /// Entries with rank <= 3, in any order.
  final List<LeaderboardEntry> entries;

  /// 0→1 once, on first build — drives the pop/rise-in entrance.
  final Animation<double> entrance;

  /// Repeating 0→1 — drives the continuous crown glow/bob.
  final Animation<double> pulse;

  LeaderboardEntry? _byRank(int rank) {
    for (final e in entries) {
      if (e.rank == rank) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final first = _byRank(1);
    final second = _byRank(2);
    final third = _byRank(3);
    if (first == null && second == null && third == null) {
      return const SizedBox.shrink();
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (second != null)
          _PodiumColumn(
            entry: second,
            tier: 2,
            entrance: entrance,
            pulse: pulse,
            delay: 0.0,
          ),
        if (second != null) const SizedBox(width: 10),
        if (first != null)
          _PodiumColumn(
            entry: first,
            tier: 1,
            entrance: entrance,
            pulse: pulse,
            delay: 0.08,
          ),
        if (third != null) const SizedBox(width: 10),
        if (third != null)
          _PodiumColumn(
            entry: third,
            tier: 3,
            entrance: entrance,
            pulse: pulse,
            delay: 0.16,
          ),
      ],
    );
  }
}

class _Tier {
  const _Tier({
    required this.columnWidth,
    required this.avatarSize,
    required this.avatarBorder,
    required this.nameSize,
    required this.nameWeight,
    required this.riserHeight,
    required this.riserBg,
    required this.riserTopBorder,
    required this.numberColor,
    required this.numberSize,
    required this.crownGlow,
  });

  final double columnWidth;
  final double avatarSize;
  final Color avatarBorder;
  final double nameSize;
  final FontWeight nameWeight;
  final double riserHeight;
  final Color riserBg;
  final Color riserTopBorder;
  final Color numberColor;
  final double numberSize;
  final Color crownGlow;

  static const first = _Tier(
    columnWidth: 108,
    avatarSize: 62,
    avatarBorder: Color(0xFF0D9488),
    nameSize: 13.5,
    nameWeight: FontWeight.w800,
    riserHeight: 80,
    riserBg: Color(0xFFFEF9C3),
    riserTopBorder: Color(0xFFF5B700),
    numberColor: Color(0xFFB45309),
    numberSize: 27,
    crownGlow: Color(0xFFF59E0B),
  );

  static const second = _Tier(
    columnWidth: 86,
    avatarSize: 48,
    avatarBorder: Color(0xFF94A3B8),
    nameSize: 12.5,
    nameWeight: FontWeight.w700,
    riserHeight: 58,
    riserBg: Color(0xFFF1F5F9),
    riserTopBorder: Color(0xFFCBD5E1),
    numberColor: Color(0xFF64748B),
    numberSize: 20,
    crownGlow: Color(0xFF94A3B8),
  );

  static const third = _Tier(
    columnWidth: 86,
    avatarSize: 48,
    avatarBorder: Color(0xFFC2703D),
    nameSize: 12.5,
    nameWeight: FontWeight.w700,
    riserHeight: 44,
    riserBg: Color(0xFFFFF3EA),
    riserTopBorder: Color(0xFFDDA772),
    numberColor: Color(0xFF9A4E20),
    numberSize: 19,
    crownGlow: Color(0xFFC2703D),
  );
}

class _PodiumColumn extends StatelessWidget {
  const _PodiumColumn({
    required this.entry,
    required this.tier,
    required this.entrance,
    required this.pulse,
    required this.delay,
  });

  final LeaderboardEntry entry;
  final int tier;
  final Animation<double> entrance;
  final Animation<double> pulse;
  final double delay;

  _Tier get _t => switch (tier) {
    1 => _Tier.first,
    2 => _Tier.second,
    _ => _Tier.third,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = _t;

    final curved = CurvedAnimation(
      parent: entrance,
      curve: Interval(
        delay,
        (delay + 0.55).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );

    return SizedBox(
      width: t.columnWidth,
      child: AnimatedBuilder(
        animation: curved,
        builder: (context, child) {
          final v = curved.value;
          return Opacity(
            opacity: v,
            child: Transform.translate(
              offset: Offset(0, (1 - v) * 16),
              child: child,
            ),
          );
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedBuilder(
                  animation: curved,
                  builder: (context, child) {
                    final scale = 0.6 + curved.value * 0.4;
                    return Transform.scale(scale: scale, child: child);
                  },
                  child: LeaderboardAvatar(
                    userId: entry.userId,
                    fullName: entry.fullName,
                    avatarUrl: entry.avatarUrl,
                    size: t.avatarSize,
                    borderColor: t.avatarBorder,
                    borderWidth: tier == 1 ? 3 : 2.5,
                  ),
                ),
                Positioned(
                  top: -8,
                  right: -2,
                  child: AnimatedBuilder(
                    animation: pulse,
                    builder: (context, child) {
                      final p = pulse.value;
                      final bob = tier == 1
                          ? math.sin(p * 2 * math.pi) * 1.5
                          : 0.0;
                      return Transform.translate(
                        offset: Offset(0, -bob),
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.emoji_events_rounded,
                      size: tier == 1 ? 24 : 17,
                      color: t.crownGlow,
                      shadows: tier == 1
                          ? [
                              Shadow(
                                color: t.crownGlow.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              entry.fullName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF0F172A),
                fontSize: t.nameSize,
                fontWeight: t.nameWeight,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${entry.score} ${l10n.leaderboardScoreSuffix}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            AnimatedBuilder(
              animation: curved,
              builder: (context, child) {
                final scaleY = curved.value.clamp(0.001, 1.0);
                return Transform(
                  alignment: Alignment.bottomCenter,
                  transform: Matrix4.diagonal3Values(1, scaleY, 1),
                  child: child,
                );
              },
              child: Container(
                width: t.columnWidth,
                height: t.riserHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.riserBg,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                  border: Border(
                    top: BorderSide(color: t.riserTopBorder, width: 3),
                  ),
                ),
                child: Text(
                  '#${entry.rank}',
                  style: TextStyle(
                    fontSize: t.numberSize,
                    fontWeight: FontWeight.w800,
                    color: t.numberColor,
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
