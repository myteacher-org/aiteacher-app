import 'package:ai_teacher/app/data/network_config.dart';
import 'package:flutter/material.dart';

/// Deterministic gradient-and-initials avatar, used whenever a leaderboard
/// entry has no [LeaderboardEntry.avatarUrl].
class LeaderboardAvatar extends StatelessWidget {
  const LeaderboardAvatar({
    super.key,
    required this.userId,
    required this.fullName,
    required this.avatarUrl,
    this.size = 36,
    this.borderColor,
    this.borderWidth = 0,
  });

  final String userId;
  final String fullName;
  final String? avatarUrl;
  final double size;
  final Color? borderColor;
  final double borderWidth;

  static const _palette = <List<Color>>[
    [Color(0xFF0D9488), Color(0xFF0A7C72)],
    [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    [Color(0xFFF59E0B), Color(0xFFD97706)],
    [Color(0xFFF472B6), Color(0xFFEC4899)],
    [Color(0xFF64748B), Color(0xFF334155)],
  ];

  List<Color> get _colors {
    if (userId.isEmpty) return _palette.first;
    final hash = userId.codeUnits.fold<int>(0, (a, b) => a + b);
    return _palette[hash % _palette.length];
  }

  String get _initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  @override
  Widget build(BuildContext context) {
    final rawUrl = avatarUrl?.trim();
    final url = rawUrl == null || rawUrl.isEmpty
        ? null
        : NetworkConfig.resolveStatic(rawUrl);
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _colors,
        ),
      ),
      child: Center(
        child: Text(
          _initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.38,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
    return Container(
      width: size,
      height: size,
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: borderWidth > 0
            ? borderColor ?? Colors.transparent
            : Colors.transparent,
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            fallback,
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }
}
