import 'package:flutter/material.dart';

class PartnerControls extends StatelessWidget {
  const PartnerControls({
    super.key,
    required this.onHistory,
    required this.onMic,
    required this.onMagic,
    required this.recording,
    required this.reportReady,
  });

  final VoidCallback onHistory;
  final VoidCallback onMic;
  final VoidCallback onMagic;
  final bool recording;
  final bool reportReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 0, 40, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _SideButton(icon: Icons.history_rounded, onTap: onHistory),
          _MicButton(active: recording, onTap: onMic),
          _MagicButton(ready: reportReady, onTap: onMagic),
        ],
      ),
    );
  }
}

class _SideButton extends StatelessWidget {
  const _SideButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D1B4B).withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: const Color(0xFF6B7A9F), size: 26),
        ),
      ),
    );
  }
}

class _MagicButton extends StatefulWidget {
  const _MagicButton({required this.ready, required this.onTap});

  final bool ready;
  final VoidCallback onTap;

  @override
  State<_MagicButton> createState() => _MagicButtonState();
}

class _MagicButtonState extends State<_MagicButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void didUpdateWidget(covariant _MagicButton old) {
    super.didUpdateWidget(old);
    if (widget.ready && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.ready) {
      _ctrl.stop();
      _ctrl.value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        final t = _ctrl.value; // 0..1 pulsing
        final glowBlur = widget.ready ? 12.0 + 20.0 * t : 12.0;
        final glowAlpha = widget.ready ? 0.25 + 0.35 * t : 0.12;
        final glowColor = widget.ready
            ? const Color(0xFF1340C4).withValues(alpha: glowAlpha)
            : const Color(0xFF0D1B4B).withValues(alpha: glowAlpha);

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: glowColor,
                    blurRadius: glowBlur,
                    spreadRadius: widget.ready ? 2.0 * t : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                widget.ready
                    ? Icons.auto_awesome_rounded
                    : Icons.auto_awesome_outlined,
                color: widget.ready
                    ? const Color(0xFF1340C4)
                    : const Color(0xFF6B7A9F),
                size: 26,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MicButton extends StatelessWidget {
  const _MicButton({required this.active, required this.onTap});

  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: active
                  ? const [Color(0xFFEF4444), Color(0xFFB91C1C)]
                  : const [Color(0xFF1340C4), Color(0xFF0D2B8E)],
            ),
            boxShadow: [
              BoxShadow(
                color:
                    (active ? const Color(0xFFEF4444) : const Color(0xFF1340C4))
                        .withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            active ? Icons.stop_rounded : Icons.mic_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }
}
