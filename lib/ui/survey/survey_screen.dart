import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/shared/widget/primary_button.dart';
import 'package:ai_teacher/ui/survey/survey_data.dart';
import 'package:ai_teacher/ui/survey/widget/survey_step_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class SurveyScreen extends StatefulWidget {
  const SurveyScreen({super.key});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final PageController _pageController = PageController();
  List<SurveyStep> _steps = const [];
  List<String?> _answers = const [];
  int _currentStep = 0;
  bool _stepsInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_stepsInitialized) {
      final l10n = AppLocalizations.of(context);
      _steps = surveySteps(l10n);
      _answers = [for (final step in _steps) step.defaultOptionId];
      _stepsInitialized = true;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _selectOption(String optionId) {
    setState(() => _answers[_currentStep] = optionId);
  }

  void _goToStep(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onContinue() {
    if (_currentStep < _steps.length - 1) {
      _goToStep(_currentStep + 1);
      return;
    }
    if (!mounted) return;
    final answers = SurveyAnswers(
      goal: _answers.isNotEmpty ? _answers[0] : null,
      level: _answers.length > 1 ? _answers[1] : null,
      dailyTime: _answers.length > 2 ? _answers[2] : null,
    );
    context.goNamed(AppRoute.login.name, extra: answers);
  }

  void _onBack() {
    if (_currentStep > 0) {
      _goToStep(_currentStep - 1);
      return;
    }
    if (!mounted) return;
    context.goNamed(AppRoute.onboarding.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canContinue = _answers[_currentStep] != null;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: AppColors.background,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) =>
                      setState(() => _currentStep = index),
                  itemCount: _steps.length,
                  itemBuilder: (context, index) {
                    return SurveyStepView(
                      step: _steps[index],
                      stepIndex: index,
                      totalSteps: _steps.length,
                      selectedOptionId: _answers[index],
                      onSelect: _selectOption,
                      onBack: _onBack,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                child: PrimaryButton(
                  label: '${l10n.commonContinue}  →',
                  enabled: canContinue,
                  onPressed: _onContinue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
