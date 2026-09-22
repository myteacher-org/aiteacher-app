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
    duration: const Duration(milliseconds: 900),
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

    return Column(
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
                                    : l.battleRankScore(mine.rank, mine.score),
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
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.navy.withValues(alpha: .08),
                              blurRadius: 22,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < ordered.length; i++) ...[
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
                                          final t =
                                              ((_controller.value - i * .10) /
                                                      .7)
                                                  .clamp(0.0, 1.0);
                                          final eased = Curves.easeOutCubic
                                              .transform(t);
                                          return Opacity(
                                            opacity: t,
                                            child: Transform.translate(
                                              offset: Offset(
                                                0,
                                                12 * (1 - eased),
                                              ),
                                              child: _PodiumPlayer(
                                                entry: ordered[i],
                                                avatar: _avatar(ordered[i]),
                                                isMe:
                                                    ordered[i].userId ==
                                                    widget.state.myUserId,
                                                stepHeight:
                                                    (ordered[i].rank == 1
                                                        ? 118
                                                        : ordered[i].rank == 2
                                                        ? 107
                                                        : 93) +
                                                    (scale > 1
                                                        ? (scale - 1) * 56
                                                        : 0),
                                                avatarScale: .92 + .08 * eased,
                                                joined: ordered.length == 3,
                                                isLeft: i == 0,
                                                isRight:
                                                    i == ordered.length - 1,
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
                      ),
                    if (entries.length > 3) ...[
                      const SizedBox(height: 12),
                      _RunnersUpSection(
                        entries: entries.skip(3).toList(),
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
                                            (a.delayMs! / 1000).toStringAsFixed(
                                              1,
                                            ),
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
                        side: const BorderSide(color: AppColors.borderStrong),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(l.battleExit, textAlign: TextAlign.center),
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
    final stepBackground = win
        ? AppColors.primary
        : entry.rank == 2
        ? const Color(0xFFDCE9EC)
        : const Color(0xFFF2E7DE);
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
                    style: const TextStyle(
                      color: Colors.white,
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
            color: stepBackground,
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
            border: win
                ? const Border(
                    top: BorderSide(color: AppColors.accent, width: 4),
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${entry.score}',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: win ? Colors.white : _slate,
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
                  color: win ? Colors.white.withValues(alpha: .72) : _muted,
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

class _RunnersUpSection extends StatelessWidget {
  const _RunnersUpSection({
    required this.entries,
    required this.myUserId,
    required this.avatarFor,
  });

  final List<ScoreboardEntry> entries;
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
    required this.avatar,
    required this.isMe,
  });

  final ScoreboardEntry entry;
  final String? avatar;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 58),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySubtle : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? const Color(0xFF99F6E4) : Colors.transparent,
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
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    entry.firstName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _slate,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (isMe)
                  Container(
                    height: 22,
                    margin: const EdgeInsets.only(left: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCCFBF1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Text(
                      l.battleYou,
                      style: const TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${entry.score}',
            style: TextStyle(
              color: isMe ? AppColors.primaryDark : _slate,
              fontSize: 13,
              fontWeight: FontWeight.w900,
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
