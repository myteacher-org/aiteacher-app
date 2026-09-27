import 'package:ai_teacher/app/data/cache_service.dart';
import 'package:ai_teacher/core/auth/data/auth_dtos.dart';
import 'package:ai_teacher/core/auth/data/auth_exception.dart';
import 'package:ai_teacher/core/auth/data/auth_repository.dart';
import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/core/auth/presentation/auth_action_state.dart';
import 'package:ai_teacher/core/purchases/presentation/purchases_controller.dart';
import 'package:ai_teacher/core/session/presentation/session_controller.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final otpControllerProvider = NotifierProvider<OtpController, AuthActionState>(
  OtpController.new,
);

class OtpController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthIdle();

  /// Verifies the OTP and immediately exchanges the verification token for
  /// auth tokens via sign-up. Works for both phone and email drafts.
  Future<AuthTokens?> verifyAndSignUp({
    required RegistrationDraft draft,
    required String code,
  }) async {
    state = const AuthLoading();
    try {
      final repo = ref.read(authRepositoryProvider);
      final verify = await repo.verifyOtp(
        phoneNumber: draft.phoneNumber,
        email: draft.email,
        code: code,
      );
      final tokens = await repo.signUp(
        draft: draft,
        verificationToken: verify.verificationToken,
      );
      ref.invalidate(currentUserProvider);
      try {
        await ref.read(currentUserProvider.future);
      } catch (_) {
        // Non-fatal: profile screen will retry on its own watch.
      }
      await ref.read(sessionControllerProvider.notifier).claimSession();
      final userId = ref.read(authSessionProvider).currentUserId;
      if (userId != null) {
        await ref.read(purchasesControllerProvider.notifier).identify(userId);
      }
      final cache = ref.read(cacheServiceProvider);
      final identifier = draft.phoneNumber ?? draft.email ?? '';
      await cache.setWebIdentifier(identifier);
      await cache.setWebPassword(draft.password);
      state = const AuthIdle();
      return tokens;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return null;
    }
  }

  Future<bool> resend(RegistrationDraft draft) async {
    state = const AuthLoading();
    try {
      await ref
          .read(authRepositoryProvider)
          .requestOtp(phoneNumber: draft.phoneNumber, email: draft.email);
      state = const AuthIdle();
      return true;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return false;
    }
  }

  void reset() => state = const AuthIdle();
}
