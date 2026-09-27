import 'package:ai_teacher/core/auth/data/auth_exception.dart';
import 'package:ai_teacher/core/auth/data/auth_repository.dart';
import 'package:ai_teacher/core/auth/presentation/auth_action_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authCheckControllerProvider =
    NotifierProvider<AuthCheckController, AuthActionState>(
      AuthCheckController.new,
    );

class AuthCheckController extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthIdle();

  /// Returns `true` when the account exists, `false` when it does not, and
  /// `null` when the check failed (state then holds the [AuthFailure]).
  Future<bool?> check({String? phoneNumber, String? email}) async {
    state = const AuthLoading();
    try {
      final exists = await ref
          .read(authRepositoryProvider)
          .exists(phoneNumber: phoneNumber, email: email);
      state = const AuthIdle();
      return exists;
    } on AuthException catch (e) {
      state = AuthFailure(e.message);
      return null;
    }
  }

  void reset() => state = const AuthIdle();
}
