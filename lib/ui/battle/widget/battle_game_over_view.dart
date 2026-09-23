import 'dart:math' as math;

import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

const _battleRed = Color(0xFFDC2626);
const _battleOrange = Color(0xFFF97316);
const _slate = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _gold = Color(0xFFF5B700);
const _silver = Color(0xFF6C8792);
const _bronze = Color(0xFFC97845);

const _revealInitialDelayMs = 300;
const _revealThirdDurationMs = 650;
const _revealFirstPauseMs = 250;
const _revealSecondDurationMs = 650;
const _revealSecondPauseMs = 300;
const _revealWinnerDurationMs = 800;
const _celebrationDurationMs = 2200;
const _winnerRevealStartMs =
    _revealInitialDelayMs +
    _revealThirdDurationMs +
    _revealFirstPauseMs +
    _revealSecondDurationMs +
    _revealSecondPauseMs;
const _winnerRevealEndMs = _winnerRevealStartMs + _revealWinnerDurationMs;
const _revealTotalMs =
    _revealInitialDelayMs +
    _revealThirdDurationMs +
    _revealFirstPauseMs +
    _revealSecondDurationMs +
    _winnerRevealEndMs +
    _celebrationDurationMs;

class BattleGameOverView extends StatefulWidget {
  const BattleGameOverView({
    super.key,
    required this.state,
    this.myAvatarPath,
    required this.onPlayAgain,
    required this.onExit,
  });
  final BattleState state;
  final String? myAvatarPath;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  @override
  State<BattleGameOverView> createState() => _BattleGameOverViewState();
}

class _BattleGameOverViewState extends State<BattleGameOverView>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _revealTotalMs),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
      _started = true;
    } else if (!_started) {
      _started = true;
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _avatar(ScoreboardEntry e) {
    final cached = widget.myAvatarPath?.trim();
    if (e.userId == widget.state.myUserId && cached?.isNotEmpty == true) {
      return cached;
    }
    return e.avatar?.trim().isNotEmpty == true ? e.avatar!.trim() : null;
  }

  double _phaseProgress(double elapsedMs, int startMs, int durationMs) {
    if (elapsedMs <= startMs) return 0;
    if (elapsedMs >= startMs + durationMs) return 1;
    return ((elapsedMs - startMs) / durationMs).clamp(0.0, 1.0);
  }

  double _podiumProgress(int rank, double controllerValue) {
    final elapsedMs = controllerValue * _revealTotalMs;
    if (rank == 3) {
      return _phaseProgress(
        elapsedMs,
        _revealInitialDelayMs,
        _revealThirdDurationMs,
      );
    }
    if (rank == 2) {
      return _phaseProgress(
        elapsedMs,
        _revealInitialDelayMs + _revealThirdDurationMs + _revealFirstPauseMs,
        _revealSecondDurationMs,
      );
    }
    return _phaseProgress(
      elapsedMs,
      _winnerRevealStartMs,
      _revealWinnerDurationMs,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Preserve server order within ties, and never use rank as a unique key.
    final indexed = widget.state.scoreboard.asMap().entries.toList()
      ..sort((a, b) {
        final rank = a.value.rank.compareTo(b.value.rank);
        return rank == 0 ? a.key.compareTo(b.key) : rank;
      });
    final entries = indexed.map((e) => e.value).toList();
    final mine = entries
        .where((e) => e.userId == widget.state.myUserId)
        .firstOrNull;
    final top = entries.take(3).toList();
    final ordered = top.length == 3
        ? [top[1], top[0], top[2]]
        : top.length == 2
        ? [top[1], top[0]]
        : top;
    final winner = mine?.rank == 1;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final hasWinner = ordered.any((entry) => entry.rank == 1);

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_battleRed, _battleOrange],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                winner
                                    ? Icons.emoji_events_rounded
                                    : Icons.auto_awesome_rounded,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    winner
                                        ? l.battleVictory
                                        : l.battleResultWellPlayed,
                                    style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w900,
                                      color: _slate,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    mine == null
                                        ? l.battleResultStandings
                                        : l.battleRankScore(
                                            mine.rank,
                                            mine.score,
                                          ),
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        if (ordered.isNotEmpty)
                          Container(
                            key: const ValueKey('podium-panel'),
                            clipBehavior: Clip.antiAlias,
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: .12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navy.withValues(alpha: .10),
                                  blurRadius: 20,
                                  offset: const Offset(0, 7),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      l.battleResultStandings,
                                      style: const TextStyle(
                                        color: AppColors.navy,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        for (
                                          var i = 0;
                                          i < ordered.length;
                                          i++
                                        ) ...[
                                          if (i > 0 && ordered.length < 3)
                                            const SizedBox(width: 8),
                                          Flexible(
                                            child: ConstrainedBox(
                                              constraints: const BoxConstraints(
                                                maxWidth: 168,
                                              ),
                                              child: AnimatedBuilder(
                                                animation: _controller,
                                                builder: (context, _) {
                                                  final t = _podiumProgress(
                                                    ordered[i].rank,
                                                    _controller.value,
                                                  );
                                                  final eased =
                                                      ordered[i].rank == 1
                                                      ? Curves.easeOutBack
                                                            .transform(t)
                                                      : Curves.easeOutCubic
                                                            .transform(t);
                                                  final winnerPulse =
                                                      ordered[i].rank == 1
                                                      ? 1 +
                                                            math.sin(
                                                                  (_phaseProgress(
                                                                        _controller.value *
                                                                            _revealTotalMs,
                                                                        _winnerRevealStartMs,
                                                                        500,
                                                                      ) *
                                                                      math.pi),
                                                                ) *
                                                                .018
                                                      : 1.0;
                                                  return Opacity(
                                                    opacity: t,
                                                    child: Transform.translate(
                                                      offset: Offset(
                                                        0,
                                                        42 * (1 - eased),
                                                      ),
                                                      child: Transform.scale(
                                                        scale: winnerPulse,
                                                        child: _PodiumPlayer(
                                                          entry: ordered[i],
                                                          avatar: _avatar(
                                                            ordered[i],
                                                          ),
                                                          isMe:
                                                              ordered[i]
                                                                  .userId ==
                                                              widget
                                                                  .state
                                                                  .myUserId,
                                                          stepHeight:
                                                              (ordered[i].rank ==
                                                                      1
                                                                  ? 126
                                                                  : ordered[i]
                                                                            .rank ==
                                                                        2
                                                                  ? 104
                                                                  : 88) +
                                                              (scale > 1
                                                                  ? (scale -
                                                                            1) *
                                                                        56
                                                                  : 0),
                                                          avatarScale:
                                                              .96 + .04 * eased,
                                                          joined:
                                                              ordered.length ==
                                                              3,
                                                          isLeft: i == 0,
                                                          isRight:
                                                              i ==
                                                              ordered.length -
                                                                  1,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        if (entries.length > 3) ...[
                          const SizedBox(height: 12),
                          _RunnersUpSection(
                            entries: entries.skip(3).toList(),
                            topScore: entries.fold<int>(
                              0,
                              (highest, entry) =>
                                  math.max(highest, entry.score),
                            ),
                            myUserId: widget.state.myUserId,
                            avatarFor: _avatar,
                          ),
                        ],
                        if (mine != null && mine.answers.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Material(
                            color: AppColors.surface,
                            clipBehavior: Clip.antiAlias,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            child: Theme(
                              data: Theme.of(
                                context,
                              ).copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                title: Text(
                                  l.battleMyAnswersLabel,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: _slate,
                                  ),
                                ),
                                children: [
                                  for (final a in mine.answers)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                        horizontal: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            a.correct
                                                ? Icons.check_circle_rounded
                                                : Icons.cancel_rounded,
                                            color: a.correct
                                                ? AppColors.primary
                                                : const Color(0xFFBE6877),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(child: Text(a.word)),
                                          if (a.delayMs != null)
                                            Text(
                                              l.battleResultSeconds(
                                                (a.delayMs! / 1000)
                                                    .toStringAsFixed(1),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: widget.onExit,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            foregroundColor: _slate,
                            backgroundColor: AppColors.surface,
                            side: const BorderSide(
                              color: AppColors.borderStrong,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            l.battleExit,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: FilledButton(
                          onPressed: widget.onPlayAgain,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            l.battlePlayAgain,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (hasWinner)
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final celebrationProgress = _phaseProgress(
                    _controller.value * _revealTotalMs,
                    _winnerRevealStartMs,
                    _celebrationDurationMs,
                  );
                  return CustomPaint(
                    painter: _WinnerCelebrationPainter(
                      progress: celebrationProgress,
                    ),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class _PodiumPlayer extends StatelessWidget {
  const _PodiumPlayer({
    required this.entry,
    required this.avatar,
    required this.isMe,
    required this.stepHeight,
    required this.avatarScale,
    required this.joined,
    required this.isLeft,
    required this.isRight,
  });
  final ScoreboardEntry entry;
  final String? avatar;
  final bool isMe;
  final double stepHeight;
  final double avatarScale;
  final bool joined;
  final bool isLeft;
  final bool isRight;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final win = entry.rank == 1;
    final stepGradient = win
        ? const [Color(0xFFFFF9DC), Color(0xFFFFF1B5)]
        : entry.rank == 2
        ? const [Color(0xFFF4F8FF), Color(0xFFE4F0FF)]
        : const [Color(0xFFFFF8F3), Color(0xFFFFEDE1)];
    final stepAccent = win
        ? AppColors.accent
        : entry.rank == 2
        ? const Color(0xFF9BC5F4)
        : const Color(0xFFE3B58D);
    final badgeColor = win
        ? AppColors.accent
        : entry.rank == 2
        ? _silver
        : _bronze;
    final avatarSize = win ? 64.0 : 56.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (win) ...[const _WinnerCrown(), const SizedBox(height: 4)],
        Transform.scale(
          scale: avatarScale,
          child: _Avatar(entry: entry, path: avatar, size: avatarSize),
        ),
        SizedBox(height: win ? 6 : 7),
        Tooltip(
          message: entry.firstName,
          child: Text(
            entry.firstName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _slate,
              fontWeight: FontWeight.w700,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 24,
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${entry.rank}',
                    style: TextStyle(
                      color: win ? AppColors.navy : Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Container(
                    height: 22,
                    padding: const EdgeInsets.symmetric(horizontal: 7),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primarySubtle,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      l.battleYou,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: win ? 4 : 7),
        Container(
          width: double.infinity,
          height: stepHeight,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: stepGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: joined
                ? BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: isLeft
                        ? const Radius.circular(16)
                        : Radius.zero,
                    bottomRight: isRight
                        ? const Radius.circular(16)
                        : Radius.zero,
                  )
                : BorderRadius.circular(16),
            border: Border(top: BorderSide(color: stepAccent, width: 4)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.score}',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.navy,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                l.battleResultPoints,
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WinnerCrown extends StatelessWidget {
  const _WinnerCrown();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 34,
      height: 24,
      child: CustomPaint(painter: _CrownPainter()),
    );
  }
}

class _CrownPainter extends CustomPainter {
  const _CrownPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = AppColors.accentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeJoin = StrokeJoin.round;
    final crown = Path()
      ..moveTo(4, 18)
      ..lineTo(2, 6)
      ..lineTo(10, 12)
      ..lineTo(17, 3)
      ..lineTo(24, 12)
      ..lineTo(32, 6)
      ..lineTo(30, 18)
      ..close();
    canvas
      ..drawPath(crown, fill)
      ..drawPath(crown, stroke)
      ..drawLine(const Offset(5, 22), const Offset(29, 22), stroke);
    final jewel = Paint()..color = const Color(0xFFFFD65A);
    canvas
      ..drawCircle(const Offset(2, 5), 2, jewel)
      ..drawCircle(const Offset(17, 2), 2, jewel)
      ..drawCircle(const Offset(32, 5), 2, jewel);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _WinnerCelebrationPainter extends CustomPainter {
  const _WinnerCelebrationPainter({required this.progress});

  final double progress;

  static const _particles = [
    _CelebrationParticle(
      angle: -2.82,
      speed: 48,
      size: 4,
      delay: .00,
      drift: -5,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: -2.46,
      speed: 60,
      size: 3,
      delay: .04,
      drift: 4,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: -2.08,
      speed: 54,
      size: 5,
      delay: .02,
      drift: -3,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: -1.73,
      speed: 64,
      size: 3,
      delay: .07,
      drift: 5,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: -1.35,
      speed: 52,
      size: 4,
      delay: .01,
      drift: -4,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: -.98,
      speed: 66,
      size: 3,
      delay: .08,
      drift: 3,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: -.61,
      speed: 50,
      size: 4,
      delay: .03,
      drift: -2,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: -.28,
      speed: 58,
      size: 3,
      delay: .06,
      drift: 4,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: .08,
      speed: 45,
      size: 4,
      delay: .02,
      drift: -3,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: .42,
      speed: 59,
      size: 3,
      delay: .09,
      drift: 5,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: .78,
      speed: 53,
      size: 4,
      delay: .04,
      drift: -4,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: 1.14,
      speed: 64,
      size: 3,
      delay: .07,
      drift: 2,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: 1.51,
      speed: 48,
      size: 5,
      delay: .01,
      drift: -5,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: 1.88,
      speed: 62,
      size: 3,
      delay: .08,
      drift: 4,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: 2.24,
      speed: 55,
      size: 4,
      delay: .03,
      drift: -2,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: 2.60,
      speed: 67,
      size: 3,
      delay: .06,
      drift: 5,
      shape: 1,
    ),
    _CelebrationParticle(
      angle: 2.94,
      speed: 49,
      size: 4,
      delay: .00,
      drift: -4,
      shape: 0,
    ),
    _CelebrationParticle(
      angle: 3.30,
      speed: 58,
      size: 3,
      delay: .05,
      drift: 3,
      shape: 1,
    ),
  ];

  static const _colors = [
    AppColors.accent,
    AppColors.primary,
    _battleOrange,
    Colors.white,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height * .43);
    final viewportReach = math.max(size.width, size.height);
    final burst = Curves.easeOutCubic.transform(
      (progress / .115).clamp(0.0, 1.0),
    );
    final paint = Paint()..style = PaintingStyle.fill;

    final glowFade = (1 - ((progress - .36) / .64)).clamp(0.0, 1.0);
    final glow = Paint()
      ..color = AppColors.accent.withValues(alpha: .14 * glowFade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(center, 20 + 12 * burst, glow);

    for (var i = 0; i < _particles.length; i++) {
      final particle = _particles[i];
      final local = ((progress - particle.delay) / (1 - particle.delay)).clamp(
        0.0,
        1.0,
      );
      if (local <= 0) continue;
      final travel = Curves.easeOutCubic.transform(
        (local / .55).clamp(0.0, 1.0),
      );
      final fall = Curves.easeIn.transform(
        ((local - .42) / .58).clamp(0.0, 1.0),
      );
      final distance = 10 + viewportReach * (particle.speed / 100) * travel;
      final position =
          center +
          Offset(math.cos(particle.angle), math.sin(particle.angle)) *
              distance +
          Offset(particle.drift * fall, 100 * fall * fall);
      final fade = (1 - ((local - .42) / .58)).clamp(0.0, 1.0);
      paint.color = _colors[i % _colors.length].withValues(alpha: .88 * fade);
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.angle + (i.isEven ? .35 : -.55) + fall * 1.8);
      if (particle.shape == 0) {
        canvas.drawCircle(
          Offset.zero,
          particle.size * (.8 + .2 * (1 - fall)),
          paint,
        );
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: particle.size * .75,
              height: particle.size * 2.2,
            ),
            const Radius.circular(2),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _WinnerCelebrationPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _CelebrationParticle {
  const _CelebrationParticle({
    required this.angle,
    required this.speed,
    required this.size,
    required this.delay,
    required this.drift,
    required this.shape,
  });

  final double angle;
  final double speed;
  final double size;
  final double delay;
  final double drift;
  final int shape;
}

class _RunnersUpSection extends StatelessWidget {
  const _RunnersUpSection({
    required this.entries,
    required this.topScore,
    required this.myUserId,
    required this.avatarFor,
  });

  final List<ScoreboardEntry> entries;
  final int topScore;
  final String? myUserId;
  final String? Function(ScoreboardEntry) avatarFor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.battleResultRunnersUp,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < entries.length; i++) ...[
            _RunnerRow(
              entry: entries[i],
              topScore: topScore,
              avatar: avatarFor(entries[i]),
              isMe: entries[i].userId == myUserId,
            ),
            if (i != entries.length - 1) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _RunnerRow extends StatelessWidget {
  const _RunnerRow({
    required this.entry,
    required this.topScore,
    required this.avatar,
    required this.isMe,
  });

  final ScoreboardEntry entry;
  final int topScore;
  final String? avatar;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySubtle : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? AppColors.primary : const Color(0xFFE5EAF0),
          width: isMe ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '${entry.rank}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isMe ? AppColors.primary : _muted,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _Avatar(entry: entry, path: avatar, size: 38),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: topScore <= 0
                              ? 0
                              : (entry.score / topScore).clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: const Color(0xFFE7EDF5),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Color(0xFF75B5F2),
                          ),
                        ),
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 7),
                      Text(
                        l.battleYou,
                        maxLines: 1,
                        style: const TextStyle(
                          color: AppColors.primaryDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              '${entry.score}',
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMe ? AppColors.primaryDark : AppColors.navy,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.entry, required this.path, required this.size});
  final ScoreboardEntry entry;
  final String? path;
  final double size;
  @override
  Widget build(BuildContext context) {
    final ring = entry.rank == 1
        ? _gold
        : entry.rank == 2
        ? Colors.white
        : entry.rank == 3
        ? Colors.white
        : Colors.transparent;
    final background = entry.rank == 1
        ? const Color(0xFF164E63)
        : entry.rank == 2
        ? const Color(0xFF3D7F92)
        : entry.rank == 3
        ? _bronze
        : _runnerAvatarColor(entry.userId);
    final fallback = Center(
      child: Text(
        entry.firstName.trim().isEmpty
            ? '?'
            : entry.firstName.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(entry.rank == 1 ? 4 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: .12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: ColoredBox(
          color: background,
          child: path == null || path!.trim().isEmpty
              ? fallback
              : Image.network(
                  NetworkConfig.resolveStatic(path!),
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => fallback,
                ),
        ),
      ),
    );
  }
}

Color _runnerAvatarColor(String seed) {
  const colors = [
    Color(0xFF7C3AED),
    Color(0xFF2563EB),
    AppColors.primary,
    Color(0xFFDB2777),
    Color(0xFFEA580C),
  ];
  return colors[seed.hashCode.abs() % colors.length];
}
