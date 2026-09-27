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

final loginControllerProvider =
    NotifierProvider<LoginController, AuthActionState>(LoginController.new);

class LoginController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthIdle();

  Future<AuthTokens?> signIn({
    String? phoneNumber,
    String? email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final tokens = await ref
          .read(authRepositoryProvider)
          .signIn(phoneNumber: phoneNumber, email: email, password: password);
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
      await cache.setWebIdentifier(email ?? phoneNumber ?? '');
      await cache.setWebPassword(password);
      state = const AuthIdle();
      return tokens;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return null;
    }
  }

  void reset() => state = const AuthIdle();
}
