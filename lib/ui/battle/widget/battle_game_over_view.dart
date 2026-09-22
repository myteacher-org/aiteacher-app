import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

const _battleRed = Color(0xFFDC2626);
const _battleOrange = Color(0xFFF97316);
const _slate = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _gold = Color(0xFFF2C765);
const _silver = Color(0xFFD7DEE8);
const _bronze = Color(0xFFE7A47E);

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

  String? _avatar(ScoreboardEntry e) => (e.avatar?.trim().isNotEmpty ?? false)
      ? e.avatar
      : e.userId == widget.state.myUserId
      ? widget.myAvatarPath
      : null;

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
                        padding: const EdgeInsets.fromLTRB(12, 16, 12, 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: .05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.workspace_premium_outlined,
                                  size: 16,
                                  color: _battleRed,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    l.battleResultStandings,
                                    style: const TextStyle(
                                      color: _muted,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
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
                                                        ? 126
                                                        : ordered[i].rank == 2
                                                        ? 100
                                                        : 78) +
                                                    (scale > 1
                                                        ? (scale - 1) * 48
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
                            if (entries.length > 3) ...[
                              const SizedBox(height: 12),
                              _RunnersUpSection(
                                entries: entries.skip(3).toList(),
                                myUserId: widget.state.myUserId,
                                avatarFor: _avatar,
                              ),
                            ],
                          ],
                        ),
                      ),
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
        ? const [AppColors.primaryLight, AppColors.primaryDark]
        : entry.rank == 2
        ? const [Color(0xFFF8FAFC), Color(0xFFE2E8F0)]
        : const [Color(0xFFFFF7ED), Color(0xFFFFE4CC)];
    final stepBorder = win
        ? const Color(0xFFE6A800)
        : entry.rank == 2
        ? const Color(0xFFCBD5E1)
        : const Color(0xFFF2A56B);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.scale(
          scale: avatarScale,
          child: _Avatar(entry: entry, path: avatar, size: 56),
        ),
        const SizedBox(height: 10),
        Tooltip(
          message: entry.firstName,
          child: Text(
            entry.firstName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _slate,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              height: 1.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 10),
          child: Text(
            isMe ? l.battleYou : ' ',
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          constraints: BoxConstraints(minHeight: stepHeight),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: stepBackground,
            ),
            borderRadius: joined
                ? BorderRadius.only(
                    topLeft: const Radius.circular(12),
                    topRight: const Radius.circular(12),
                    bottomLeft: isLeft
                        ? const Radius.circular(12)
                        : Radius.zero,
                    bottomRight: isRight
                        ? const Radius.circular(12)
                        : Radius.zero,
                  )
                : BorderRadius.circular(12),
            border: Border.all(color: stepBorder, width: win ? 2 : 1),
          ),
          child: Column(
            children: [
              Text(
                '${entry.score}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: win ? Colors.white : _slate,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                l.battleResultPoints,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: win ? Colors.white.withValues(alpha: .82) : _muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.tintSlate,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.battleResultRunnersUp,
            style: const TextStyle(
              color: _slate,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 310 ? 2 : 1;
              final width = columns == 2
                  ? (constraints.maxWidth - 8) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final entry in entries)
                    SizedBox(
                      width: width,
                      child: _RunnerChip(
                        entry: entry,
                        avatar: avatarFor(entry),
                        isMe: entry.userId == myUserId,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RunnerChip extends StatelessWidget {
  const _RunnerChip({
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
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primarySubtle : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMe
              ? AppColors.primary.withValues(alpha: .3)
              : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Text(
              '${entry.rank}',
              style: const TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _Avatar(entry: entry, path: avatar, size: 28, badge: false),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.firstName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _slate,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (isMe)
                  Text(
                    l.battleYou,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.score}',
            style: const TextStyle(
              color: _slate,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.entry,
    required this.path,
    required this.size,
    this.badge = true,
  });
  final ScoreboardEntry entry;
  final String? path;
  final double size;
  final bool badge;
  @override
  Widget build(BuildContext context) {
    final ring = entry.rank == 1
        ? _gold
        : entry.rank == 2
        ? _silver
        : _bronze;
    final fallback = Center(
      child: Text(
        entry.firstName.trim().isEmpty
            ? '?'
            : entry.firstName.trim().characters.first.toUpperCase(),
        style: TextStyle(
          color: _slate,
          fontSize: size * .36,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    return SizedBox(
      width: size + 4,
      height: size + (badge ? 6 : 0),
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(shape: BoxShape.circle, color: ring),
            child: ClipOval(
              child: ColoredBox(
                color: AppColors.tintSlate,
                child: path == null || path!.trim().isEmpty
                    ? fallback
                    : Image.network(
                        NetworkConfig.resolveStatic(path!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => fallback,
                      ),
              ),
            ),
          ),
          if (badge)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ring,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surface, width: 2),
                ),
                child: Text(
                  '${entry.rank}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: _slate,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
