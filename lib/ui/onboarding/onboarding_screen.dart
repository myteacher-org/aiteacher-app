import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/onboarding/widget/glow_avatar.dart';
import 'package:ai_teacher/ui/onboarding/widget/lekin_divider.dart';
import 'package:ai_teacher/ui/onboarding/widget/welcome_cta.dart';
import 'package:ai_teacher/ui/onboarding/widget/welcome_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.navy,
      ),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Align(alignment: Alignment.center, child: WelcomeLogo()),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const GlowAvatar(),
                      const SizedBox(height: 32),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(text: l10n.onboardingHeroLine1),
                            TextSpan(
                              text: l10n.onboardingHeroHighlight1,
                              style: const TextStyle(
                                color: AppColors.primaryLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const LekinDivider(),
                      const SizedBox(height: 20),
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(text: l10n.onboardingHeroLine2),
                            TextSpan(
                              text: l10n.onboardingHeroHighlight2,
                              style: const TextStyle(color: AppColors.accent),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.onboardingHeroSubtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF8FA3B5),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                WelcomeCta(
                  label: '${l10n.onboardingCtaLabel}  →',
                  onPressed: () => context.pushNamed(AppRoute.login.name),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.onboardingHaveAccount,
                      style: const TextStyle(
                        color: Color(0xFF8FA3B5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.pushNamed(AppRoute.login.name),
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        l10n.onboardingLoginLink,
                        style: const TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
