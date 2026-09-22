import 'package:ai_teacher/core/battle/data/battle_reaction_codes.dart';
import 'package:flutter/material.dart';

/// Slim row of quick-tap emoji reactions sent to the opponent mid-match.
/// Each button sends the backend's reaction *code* (e.g. "strong"), not the
/// raw emoji glyph — see [battleReactionCodes].
class BattleReactionBar extends StatelessWidget {
  const BattleReactionBar({super.key, required this.onReact});

  final void Function(String code) onReact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final code in battleReactionCodes)
          _ReactionButton(code: code, onTap: () => onReact(code)),
      ],
    );
  }
}

class _ReactionButton extends StatefulWidget {
  const _ReactionButton({required this.code, required this.onTap});

  final String code;
  final VoidCallback onTap;

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  );

  DateTime? _lastTap;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Throttle: at most ~2 taps/sec, matching the server-side rate limit.
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 500) {
      return;
    }
    _lastTap = now;
    _controller.forward(from: 0);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = _controller.value;
          final bump = t < 0.5 ? t * 2 : (1 - t) * 2;
          final scale = 1.0 + bump * 0.35;
          return Transform.scale(scale: scale, child: child);
        },
        child: Text(
          battleReactionEmojiFor(widget.code),
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
