import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:flutter/material.dart';

/// Wraps the whole app and shows a thin bar docked above the soft keyboard
/// while it is open. The bar has a single button that closes the keyboard.
///
/// The bar's height is added to `viewInsets.bottom` for everything below, so
/// scaffolds resize above the bar instead of being covered by it, and
/// existing `viewInsetsOf(context).bottom > 0` checks keep working.
class KeyboardDismissBarHost extends StatelessWidget {
  const KeyboardDismissBarHost({super.key, required this.child});

  final Widget child;

  static const double barHeight = 44;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardInset = mediaQuery.viewInsets.bottom;
    if (keyboardInset <= 0) return child;

    return Stack(
      children: [
        MediaQuery(
          data: mediaQuery.copyWith(
            viewInsets: mediaQuery.viewInsets.copyWith(
              bottom: keyboardInset + barHeight,
            ),
          ),
          child: child,
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: keyboardInset,
          height: barHeight,
          child: const _KeyboardDismissBar(),
        ),
      ],
    );
  }
}

class _KeyboardDismissBar extends StatelessWidget {
  const _KeyboardDismissBar();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Material(
          color: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: const Color(0x33000000),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: const SizedBox(
              width: 36,
              height: 36,
              child: Icon(
                Icons.keyboard_hide_rounded,
                size: 20,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
