import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class NavTab {
  const NavTab({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
  });

  final String label;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
    this.chatBadge = false,
    this.hideCoursesTab = false,
  });

  final int activeIndex;
  final ValueChanged<int> onTap;
  final bool chatBadge;
  final bool hideCoursesTab;

  // Each entry: (originalIndex, NavTab)
  List<(int, NavTab)> _allTabs(AppLocalizations l10n) => <(int, NavTab)>[
    (
      0,
      NavTab(
        label: l10n.navTabChat,
        icon: Icons.chat_bubble_outline_rounded,
        iconColor: AppColors.primary,
        iconBackground: const Color(0xFFF0FDFA),
      ),
    ),
    (
      1,
      NavTab(
        label: l10n.navTabCourses,
        icon: Icons.school_rounded,
        iconColor: const Color(0xFF22C55E),
        iconBackground: const Color(0xFFF0FDF4),
      ),
    ),
    (
      2,
      NavTab(
        label: l10n.navTabHome,
        icon: Icons.home_rounded,
        iconColor: AppColors.primary,
        iconBackground: const Color(0xFFCCFBF1),
      ),
    ),
    (
      3,
      NavTab(
        label: l10n.navTabBlog,
        icon: Icons.article_outlined,
        iconColor: const Color(0xFFFB923C),
        iconBackground: const Color(0xFFFFF7ED),
      ),
    ),
    (
      4,
      NavTab(
        label: l10n.navTabProfile,
        icon: Icons.person_outline_rounded,
        iconColor: const Color(0xFFA855F7),
        iconBackground: const Color(0xFFFDF4FF),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allTabs = _allTabs(l10n);
    final tabs = hideCoursesTab
        ? allTabs.where((e) => e.$1 != 1).toList()
        : allTabs;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0x12000000), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            for (final (originalIndex, tab) in tabs)
              Expanded(
                child: _NavItem(
                  tab: tab,
                  active: originalIndex == activeIndex,
                  badge: originalIndex == 0 && chatBadge,
                  onTap: () => onTap(originalIndex),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.active,
    required this.onTap,
    this.badge = false,
  });

  final NavTab tab;
  final bool active;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : tab.iconBackground,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: active
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    tab.icon,
                    color: active ? Colors.white : tab.iconColor,
                    size: 20,
                  ),
                ),
                if (badge)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              tab.label,
              style: TextStyle(
                color: active ? AppColors.primary : const Color(0xFFBBBBBB),
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
