import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_avatar.dart';
import 'package:flutter/material.dart';

/// One ranked row below the podium (rank > 3). Also reused, with
/// [highlighted], for the sticky "you" card.
class LeaderboardRow extends StatelessWidget {
  const LeaderboardRow({
    super.key,
    required this.entry,
    required this.subtitle,
    required this.scoreRatio,
    this.highlighted = false,
    this.entrance,
    this.pulse,
    this.delay = 0,
  });

  final LeaderboardEntry entry;
  final String subtitle;

  /// This entry's score relative to the top score visible in the list
  /// (0–1), used for the subtle progress fill under the name.
  final double scoreRatio;
  final bool highlighted;

  /// 0→1 once — drives this row's rise-in. Null skips the entrance (used
  /// for the always-visible sticky "you" card, which shouldn't re-animate
  /// every rebuild).
  final Animation<double>? entrance;

  /// Repeating 0→1 — drives the streak flame's flicker.
  final Animation<double>? pulse;

  /// Stagger offset (0–1) into [entrance] for this row's Interval.
  final double delay;

  @override
  Widget build(BuildContext context) {
    final fg = highlighted ? const Color(0xFF0A5F58) : const Color(0xFF0A1628);
    final rankColor = highlighted
        ? const Color(0xFF0D9488)
        : const Color(0xFF94A3B8);

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF0FDFA) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: highlighted
            ? Border.all(color: const Color(0xFF0D9488), width: 1.4)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 26,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: rankColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(width: 10),
          LeaderboardAvatar(
            userId: entry.userId,
            fullName: entry.fullName,
            avatarUrl: entry.avatarUrl,
            size: 38,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 5),
                _ScoreBar(ratio: scoreRatio, entrance: entrance, delay: delay),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: highlighted
                          ? const Color(0xFF0A7C72)
                          : const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _PulsingFlame(pulse: pulse),
                const SizedBox(width: 3),
                Text(
                  '${entry.streakDays}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEA580C),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 48,
            child: Text(
              '${entry.score}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: fg,
                letterSpacing: -0.2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );

    final entranceAnim = entrance;
    if (entranceAnim == null) return content;

    final curved = CurvedAnimation(
      parent: entranceAnim,
      curve: Interval(
        delay.clamp(0.0, 1.0),
        (delay + 0.4).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, (1 - curved.value) * 14),
          child: child,
        ),
      ),
      child: content,
    );
  }
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({required this.ratio, this.entrance, required this.delay});

  final double ratio;
  final Animation<double>? entrance;
  final double delay;

  @override
  Widget build(BuildContext context) {
    final track = Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
    );

    final entranceAnim = entrance;
    final fillFraction = ratio.clamp(0.05, 1.0);

    Widget fill(double growth) => FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: fillFraction * growth,
      child: Container(
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFBFDBFE),
          borderRadius: BorderRadius.circular(999),
        ),
      ),
    );

    return Stack(
      children: [
        track,
        if (entranceAnim == null)
          fill(1)
        else
          AnimatedBuilder(
            animation: CurvedAnimation(
              parent: entranceAnim,
              curve: Interval(
                (delay + 0.1).clamp(0.0, 1.0),
                (delay + 0.55).clamp(0.0, 1.0),
                curve: Curves.easeOutCubic,
              ),
            ),
            builder: (context, _) {
              final t = CurvedAnimation(
                parent: entranceAnim,
                curve: Interval(
                  (delay + 0.1).clamp(0.0, 1.0),
                  (delay + 0.55).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic,
                ),
              ).value;
              return fill(t);
            },
          ),
      ],
    );
  }
}

class _PulsingFlame extends StatelessWidget {
  const _PulsingFlame({this.pulse});

  final Animation<double>? pulse;

  @override
  Widget build(BuildContext context) {
    const flame = Text('🔥', style: TextStyle(fontSize: 13));
    final p = pulse;
    if (p == null) return flame;
    return AnimatedBuilder(
      animation: p,
      builder: (context, child) {
        final t = p.value;
        final scale = 1.0 + (t < 0.5 ? t : 1 - t) * 0.22;
        return Transform.scale(scale: scale, child: child);
      },
      child: flame,
    );
  }
}
