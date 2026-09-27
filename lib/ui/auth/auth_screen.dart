import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/app/theme/app_theme.dart';
import 'package:ai_teacher/core/auth/presentation/auth_action_state.dart';
import 'package:ai_teacher/core/auth/presentation/auth_check_controller.dart';
import 'package:ai_teacher/core/auth/presentation/login_controller.dart';
import 'package:ai_teacher/core/auth/presentation/register_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/auth/widget/auth_header.dart';
import 'package:ai_teacher/ui/auth/widget/auth_identifier_toggle.dart';
import 'package:ai_teacher/ui/auth/widget/labeled_field.dart';
import 'package:ai_teacher/ui/auth/widget/password_field.dart';
import 'package:ai_teacher/ui/auth/widget/phone_field.dart';
import 'package:ai_teacher/ui/shared/widget/primary_button.dart';
import 'package:ai_teacher/ui/survey/survey_data.dart';
import 'package:ai_teacher/utils/uz_phone_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

enum _AuthStep { identify, login, register }

/// Single entry point for sign-in and sign-up. The user first enters a phone
/// number or email; the server tells us whether that account exists, and we
/// show the login or register form accordingly.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key, this.surveyAnswers});

  final SurveyAnswers? surveyAnswers;

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _referralController = TextEditingController();
  AuthIdentifierKind _identifierKind = AuthIdentifierKind.phone;
  _AuthStep _step = _AuthStep.identify;
  bool _hasReferral = false;

  bool get _isPhone => _identifierKind == AuthIdentifierKind.phone;

  String get _phoneE164 => UzPhoneFormatter.toE164(_phoneController.text);

  String get _email => _emailController.text.trim();

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (_step != _AuthStep.identify) {
      _resetToIdentify();
      return;
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.onboarding.name);
    }
  }

  void _resetToIdentify() {
    setState(() {
      _step = _AuthStep.identify;
      _passwordController.clear();
    });
  }

  void _onForgot() {
    // Forgot-password flow not implemented yet.
  }

  Future<void> _onSubmit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;
    FocusScope.of(context).unfocus();
    switch (_step) {
      case _AuthStep.identify:
        await _checkExistence();
      case _AuthStep.login:
        await _signIn();
      case _AuthStep.register:
        await _register();
    }
  }

  Future<void> _checkExistence() async {
    final exists = await ref
        .read(authCheckControllerProvider.notifier)
        .check(
          phoneNumber: _isPhone ? _phoneE164 : null,
          email: _isPhone ? null : _email,
        );
    if (!mounted || exists == null) return;
    setState(() => _step = exists ? _AuthStep.login : _AuthStep.register);
  }

  Future<void> _signIn() async {
    final tokens = await ref
        .read(loginControllerProvider.notifier)
        .signIn(
          phoneNumber: _isPhone ? _phoneE164 : null,
          email: _isPhone ? null : _email,
          password: _passwordController.text,
        );
    if (!mounted || tokens == null) return;
    context.goNamed(AppRoute.main.name);
  }

  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final parts = fullName.split(RegExp(r'\s+'));
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.skip(1).join(' ') : '';

    final survey = widget.surveyAnswers;
    final referral = _hasReferral && _referralController.text.trim().isNotEmpty
        ? _referralController.text.trim()
        : null;
    final controller = ref.read(registerControllerProvider.notifier);
    final draft = _isPhone
        ? await controller.requestOtp(
            firstName: firstName,
            lastName: lastName,
            phoneNumber: _phoneE164,
            password: _passwordController.text,
            goal: survey?.goal,
            level: survey?.level,
            dailyTime: survey?.dailyTime,
            referralCode: referral,
          )
        : await controller.requestEmailOtp(
            firstName: firstName,
            lastName: lastName,
            email: _email,
            password: _passwordController.text,
            goal: survey?.goal,
            level: survey?.level,
            dailyTime: survey?.dailyTime,
            referralCode: referral,
          );
    if (!mounted || draft == null) return;
    context.pushNamed(AppRoute.otp.name, extra: draft);
  }

  String? _validateName(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.authNameRequiredError;
    if (v.length < 2) return l10n.authNameTooShortError;
    return null;
  }

  String? _validatePhone(String? value, AppLocalizations l10n) {
    final digits = UzPhoneFormatter.digitsOf(value ?? '');
    if (digits.isEmpty) return l10n.authPhoneRequiredError;
    if (digits.length != 9) return l10n.authPhoneDigitsError;
    return null;
  }

  String? _validateEmail(String? value, AppLocalizations l10n) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return l10n.authEmailRequiredError;
    final ok = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(v);
    if (!ok) return l10n.authEmailInvalidError;
    return null;
  }

  String? _validatePassword(String? value, AppLocalizations l10n) {
    final v = value ?? '';
    if (v.isEmpty) return l10n.authPasswordRequiredError;
    if (v.length < 6) return l10n.authPasswordMinLengthError;
    return null;
  }

  void _listenForFailure(
    ProviderListenable<AuthActionState> provider,
    VoidCallback reset,
  ) {
    ref.listen<AuthActionState>(provider, (prev, next) {
      if (next is AuthFailure) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(next.message)));
        reset();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _listenForFailure(
      authCheckControllerProvider,
      () => ref.read(authCheckControllerProvider.notifier).reset(),
    );
    _listenForFailure(
      loginControllerProvider,
      () => ref.read(loginControllerProvider.notifier).reset(),
    );
    _listenForFailure(
      registerControllerProvider,
      () => ref.read(registerControllerProvider.notifier).reset(),
    );

    final loading =
        switch (_step) {
              _AuthStep.identify => ref.watch(authCheckControllerProvider),
              _AuthStep.login => ref.watch(loginControllerProvider),
              _AuthStep.register => ref.watch(registerControllerProvider),
            }
            is AuthLoading;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final (titleStart, titleAccent, subtitle) = switch (_step) {
      _AuthStep.identify => (
        l10n.authIdentifyTitleStart,
        l10n.authIdentifyTitleAccent,
        l10n.authIdentifySubtitle,
      ),
      _AuthStep.login => (
        l10n.authLoginTitleStart,
        l10n.authLoginTitleAccent,
        l10n.authLoginSubtitle,
      ),
      _AuthStep.register => (
        l10n.authRegisterTitleStart,
        l10n.authRegisterTitleAccent,
        l10n.authRegisterSubtitle,
      ),
    };

    final submitLabel = switch (_step) {
      _AuthStep.identify =>
        loading ? l10n.authCheckingLabel : l10n.authContinueButtonLabel,
      _AuthStep.login =>
        loading ? l10n.authLoginLoadingLabel : l10n.authLoginSubmitLabel,
      _AuthStep.register =>
        loading ? l10n.authRegisterLoadingLabel : l10n.authContinueButtonLabel,
    };

    return PopScope(
      canPop: _step == _AuthStep.identify,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _resetToIdentify();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: AppColors.background,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                AuthHeader(
                  titleStart: titleStart,
                  titleAccent: titleAccent,
                  subtitle: subtitle,
                  onBack: _onBack,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: switch (_step) {
                        _AuthStep.identify => _buildIdentifyFields(l10n),
                        _AuthStep.login => _buildLoginFields(l10n),
                        _AuthStep.register => _buildRegisterFields(l10n),
                      },
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      12,
                      24,
                      isKeyboardOpen ? 12 : 32,
                    ),
                    child: PrimaryButton(
                      label: submitLabel,
                      enabled: !loading,
                      onPressed: _onSubmit,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildIdentifyFields(AppLocalizations l10n) {
    return [
      AuthIdentifierToggle(
        value: _identifierKind,
        onChanged: (kind) => setState(() => _identifierKind = kind),
      ),
      const SizedBox(height: 16),
      if (_isPhone)
        PhoneField(
          label: l10n.authPhoneNumberLabel,
          hint: l10n.authPhoneNumberHint,
          controller: _phoneController,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onSubmit(),
          validator: (value) => _validatePhone(value, l10n),
        )
      else
        LabeledField(
          label: l10n.authEmailLabel,
          hint: l10n.authEmailHint,
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onSubmit(),
          validator: (value) => _validateEmail(value, l10n),
        ),
    ];
  }

  Widget _buildIdentifierSummary(AppLocalizations l10n) {
    return _IdentifierSummary(
      label: _isPhone ? l10n.authPhoneNumberLabel : l10n.authEmailLabel,
      value: _isPhone
          ? '${l10n.authPhoneCountryPrefix} ${_phoneController.text}'
          : _email,
      changeLabel: l10n.authChangeIdentifierLabel,
      onChange: _resetToIdentify,
    );
  }

  List<Widget> _buildLoginFields(AppLocalizations l10n) {
    return [
      _buildIdentifierSummary(l10n),
      const SizedBox(height: 16),
      PasswordField(
        label: l10n.authPasswordLabel,
        hint: l10n.authPasswordHint,
        controller: _passwordController,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _onSubmit(),
        validator: (value) => _validatePassword(value, l10n),
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _onForgot,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              l10n.authForgotPasswordLabel,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildRegisterFields(AppLocalizations l10n) {
    return [
      _buildIdentifierSummary(l10n),
      const SizedBox(height: 16),
      LabeledField(
        label: l10n.authNameLabel,
        hint: l10n.authNameHint,
        controller: _nameController,
        textInputAction: TextInputAction.next,
        validator: (value) => _validateName(value, l10n),
      ),
      const SizedBox(height: 16),
      PasswordField(
        label: l10n.authPasswordLabel,
        hint: l10n.authPasswordMinLengthError,
        controller: _passwordController,
        textInputAction: _hasReferral
            ? TextInputAction.next
            : TextInputAction.done,
        onFieldSubmitted: _hasReferral ? null : (_) => _onSubmit(),
        validator: (value) => _validatePassword(value, l10n),
      ),
      const SizedBox(height: 8),
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() {
          _hasReferral = !_hasReferral;
          if (!_hasReferral) _referralController.clear();
        }),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _hasReferral,
                  onChanged: (v) => setState(() {
                    _hasReferral = v ?? false;
                    if (!_hasReferral) {
                      _referralController.clear();
                    }
                  }),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                l10n.authHasReferralLabel,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
      if (_hasReferral) ...[
        const SizedBox(height: 12),
        LabeledField(
          label: l10n.authReferralCodeLabel,
          hint: l10n.authReferralCodeHint,
          controller: _referralController,
          textInputAction: TextInputAction.done,
          keyboardType: TextInputType.text,
          onFieldSubmitted: (_) => _onSubmit(),
        ),
      ],
    ];
  }
}

/// Read-only display of the phone/email the user already confirmed, with an
/// action to go back and change it.
class _IdentifierSummary extends StatelessWidget {
  const _IdentifierSummary({
    required this.label,
    required this.value,
    required this.changeLabel,
    required this.onChange,
  });

  final String label;
  final String value;
  final String changeLabel;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 7),
        Container(
          height: 52,
          padding: const EdgeInsets.only(left: 16, right: 4),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.inputCornerRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: onChange,
                child: Text(
                  changeLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
