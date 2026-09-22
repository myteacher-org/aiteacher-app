import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/leaderboard/data/leaderboard_entry.dart';
import 'package:ai_teacher/core/leaderboard/data/leaderboard_not_ranked_exception.dart';
import 'package:ai_teacher/core/leaderboard/presentation/leaderboard_controller.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_not_ranked_view.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_podium.dart';
import 'package:ai_teacher/ui/leaderboard/widget/leaderboard_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  void _onBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(leaderboardProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(onBack: () => _onBack(context)),
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.4),
                ),
                error: (e, _) => e is LeaderboardNotRankedException
                    ? const LeaderboardNotRankedView()
                    : _ErrorState(
                        onRetry: () => ref.invalidate(leaderboardProvider),
                      ),
                data: (entries) => _LeaderboardBody(
                  entries: entries,
                  myUserId: currentUser?.id,
                  myAvatarPath: currentUser?.avatar,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 20, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded),
            color: const Color(0xFF0F172A),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.leaderboardTitle,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                Text(
                  l10n.leaderboardUpdatedNightly,
                  style: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
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

class _LeaderboardBody extends StatefulWidget {
  const _LeaderboardBody({
    required this.entries,
    this.myUserId,
    this.myAvatarPath,
  });

  final List<LeaderboardEntry> entries;
  final String? myUserId;
  final String? myAvatarPath;

  @override
  State<_LeaderboardBody> createState() => _LeaderboardBodyState();
}

class _LeaderboardBodyState extends State<_LeaderboardBody>
    with TickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _entrance.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cachedAvatar = widget.myAvatarPath?.trim();
    final entries = widget.entries
        .map((entry) {
          final isMe =
              entry.isMe ||
              (widget.myUserId?.isNotEmpty == true &&
                  entry.userId == widget.myUserId);
          if (!isMe) return entry;
          return LeaderboardEntry(
            userId: entry.userId,
            fullName: entry.fullName,
            avatarUrl: isMe && cachedAvatar?.isNotEmpty == true
                ? cachedAvatar
                : entry.avatarUrl,
            score: entry.score,
            rank: entry.rank,
            streakDays: entry.streakDays,
            isMe: isMe,
          );
        })
        .toList(growable: false);
    final sorted = [...entries]..sort((a, b) => a.rank.compareTo(b.rank));
    final podium = sorted.where((e) => e.rank <= 3).toList(growable: false);
    final rows = sorted.where((e) => e.rank > 3).toList(growable: false);

    LeaderboardEntry? me;
    for (final e in sorted) {
      if (e.isMe) {
        me = e;
        break;
      }
    }

    String? toNextSubtitle;
    if (me != null) {
      final meIndex = sorted.indexOf(me);
      if (meIndex > 0) {
        final above = sorted[meIndex - 1];
        if (above.rank == me.rank - 1 && above.score > me.score) {
          toNextSubtitle = l10n.leaderboardToNextRank(above.score - me.score);
        }
      }
    }

    final highestScore = sorted.isEmpty
        ? 0
        : sorted.map((e) => e.score).reduce((a, b) => a > b ? a : b);
    final topScore = highestScore > 0 ? highestScore : 1;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            children: [
              if (podium.isNotEmpty)
                LeaderboardPodium(
                  entries: podium,
                  entrance: _entrance,
                  pulse: _pulse,
                ),
              if (rows.isNotEmpty) const SizedBox(height: 18),
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                if (i > 0 && rows[i].rank - rows[i - 1].rank > 1)
                  const _RankGapDivider(),
                LeaderboardRow(
                  entry: rows[i],
                  subtitle: rows[i].isMe ? l10n.leaderboardYou : '',
                  scoreRatio: rows[i].score / topScore,
                  highlighted: rows[i].isMe,
                  entrance: _entrance,
                  pulse: _pulse,
                  delay: (0.25 + i * 0.06).clamp(0.0, 0.85),
                ),
              ],
            ],
          ),
        ),
        if (me != null)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0A1628).withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, -6),
                ),
              ],
            ),
            child: LeaderboardRow(
              entry: me,
              subtitle: toNextSubtitle ?? l10n.leaderboardYou,
              scoreRatio: me.score / topScore,
              highlighted: true,
              pulse: _pulse,
            ),
          ),
      ],
    );
  }
}

class _RankGapDivider extends StatelessWidget {
  const _RankGapDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Center(
        child: Text(
          '· · ·',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 2,
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
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.leaderboardErrorState,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF8A8580),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onRetry, child: Text(l10n.commonRetry)),
          ],
        ),
      ),
    );
  }
}
