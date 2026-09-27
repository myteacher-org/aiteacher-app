import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

/// Entry point into the leaderboard, shown just under the profile picture
/// and info. Carries a small looping "live" pulse (glow ring + dot) so it
/// reads as something that updates, not a static settings row.
class ProfileLeaderboardCard extends StatefulWidget {
  const ProfileLeaderboardCard({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  State<ProfileLeaderboardCard> createState() => _ProfileLeaderboardCardState();
}

class _ProfileLeaderboardCardState extends State<ProfileLeaderboardCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _PulsingTrophyIcon(controller: _controller),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              l10n.profileLeaderboardTitle,
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _LiveDot(controller: _controller),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          l10n.profileLeaderboardSubtitle,
                          style: const TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFFC0C0C0),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PulsingTrophyIcon extends StatelessWidget {
  const _PulsingTrophyIcon({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final t = controller.value;
        final ringScale = 1.0 + (t * 0.5);
        final ringOpacity = (1.0 - t).clamp(0.0, 1.0) * 0.35;
        return SizedBox(
          width: 34,
          height: 34,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Transform.scale(
                scale: ringScale,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFF5B700,
                    ).withValues(alpha: ringOpacity),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: Container(
        width: 34,
        height: 34,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFEF3C7), Color(0xFFF59E0B)],
          ),
        ),
        alignment: Alignment.center,
        child: const Icon(
          Icons.emoji_events_rounded,
          color: Color(0xFFB45309),
          size: 17,
        ),
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = (controller.value * 2).clamp(0.0, 1.0);
        final pulse = t < 1.0 ? (0.6 + (1 - t) * 0.4) : 0.6;
        return Opacity(
          opacity: pulse,
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF22C55E),
            ),
          ),
        );
      },
    );
  }
}
