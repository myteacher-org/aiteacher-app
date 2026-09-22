import 'dart:async';

import 'package:ai_teacher/core/battle/data/battle_dtos.dart';
import 'package:ai_teacher/core/battle/data/battle_reaction_codes.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/battle/widget/battle_reaction_bar.dart';
import 'package:flutter/material.dart';

class BattleQueueView extends StatefulWidget {
  const BattleQueueView({
    super.key,
    required this.lobbyPlayers,
    required this.onCancel,
    required this.onReact,
    required this.reactions,
    this.myUserId,
    this.lobbyTick,
  });

  final List<LobbyPlayer> lobbyPlayers;
  final VoidCallback onCancel;

  /// Sends a reaction code to the rest of the lobby while waiting.
  final void Function(String code) onReact;
  final Stream<PlayerReaction> reactions;
  final String? myUserId;
  final int? lobbyTick;

  @override
  State<BattleQueueView> createState() => _BattleQueueViewState();
}

class _QueueReaction {
  _QueueReaction({required this.id, required this.userId, required this.code});

  final int id;
  final String userId;
  final String code;
}

class _BattleQueueViewState extends State<BattleQueueView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  final List<_QueueReaction> _activeReactions = [];
  late final StreamSubscription<PlayerReaction> _reactionSub;
  int _nextId = 0;

  @override
  void initState() {
    super.initState();
    _reactionSub = widget.reactions.listen((r) {
      _addReaction(userId: r.userId, code: r.emoji);
    });
  }

  @override
  void dispose() {
    _pulse.dispose();
    _reactionSub.cancel();
    super.dispose();
  }

  void _addReaction({required String userId, required String code}) {
    if (!mounted) return;
    final id = _nextId++;
    setState(
      () => _activeReactions.add(
        _QueueReaction(id: id, userId: userId, code: code),
      ),
    );
    Timer(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      setState(() => _activeReactions.removeWhere((r) => r.id == id));
    });
  }

  void _handleReact(String code) {
    widget.onReact(code);
    final myUserId = widget.myUserId;
    if (myUserId != null) _addReaction(userId: myUserId, code: code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final count = widget.lobbyPlayers.length;
    const max = 4;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, child) {
              final scale = 1.0 + _pulse.value * 0.12;
              return Transform.scale(scale: scale, child: child);
            },
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.4),
                    blurRadius: 32,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: const Text('⚔️', style: TextStyle(fontSize: 46)),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            l10n.battleQueueWaitingTitle,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.battleQueuePlayerCount(count, max),
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (widget.lobbyTick != null) ...[
                const SizedBox(width: 10),
                const Text(
                  '·',
                  style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.lobbyTick}s',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 36),
          _PlayerSlots(
            players: widget.lobbyPlayers,
            maxPlayers: max,
            activeReactions: _activeReactions,
          ),
          const SizedBox(height: 32),
          BattleReactionBar(onReact: _handleReact),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.onCancel,
            child: Text(
              l10n.commonCancel,
              style: const TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerSlots extends StatelessWidget {
  const _PlayerSlots({
    required this.players,
    required this.maxPlayers,
    required this.activeReactions,
  });

  final List<LobbyPlayer> players;
  final int maxPlayers;
  final List<_QueueReaction> activeReactions;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(maxPlayers, (i) {
        final filled = i < players.length;
        final reaction = filled
            ? activeReactions.lastWhereOrNull(
                (r) => r.userId == players[i].userId,
              )
            : null;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? const Color(0xFFDC2626).withValues(alpha: 0.12)
                          : const Color(0xFFF1F5F9),
                      border: Border.all(
                        color: filled
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: filled
                        ? Text(
                            players[i].firstName.isNotEmpty
                                ? players[i].firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFFCBD5E1),
                            size: 22,
                          ),
                  ),
                  if (reaction != null)
                    Positioned(
                      top: -46,
                      child: _ReactionBubble(
                        key: ValueKey(reaction.id),
                        code: reaction.code,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: 60,
                child: Text(
                  filled ? players[i].firstName : '...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: filled
                        ? const Color(0xFF334155)
                        : const Color(0xFFCBD5E1),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ReactionBubble extends StatelessWidget {
  const _ReactionBubble({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1600),
        curve: Curves.easeOut,
        builder: (context, t, child) {
          final opacity = t < 0.75 ? 1.0 : (1 - (t - 0.75) / 0.25).clamp(0.0, 1.0);
          final pop = t < 0.15 ? (t / 0.15) : 1.0;
          return Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, -14 * t),
              child: Transform.scale(scale: 0.4 + pop * 0.8, child: child),
            ),
          );
        },
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            battleReactionEmojiFor(code),
            style: const TextStyle(fontSize: 26),
          ),
        ),
      ),
    );
  }
}

extension _LastWhereOrNull<T> on List<T> {
  T? lastWhereOrNull(bool Function(T) test) {
    for (var i = length - 1; i >= 0; i--) {
      if (test(this[i])) return this[i];
    }
    return null;
  }
}
