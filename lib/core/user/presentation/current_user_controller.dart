import 'package:ai_teacher/core/user/data/user_dtos.dart';
import 'package:ai_teacher/core/user/data/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getMe();
});

/// Whether the signed-in account is a demo account (see [User.isDemo]).
/// Payment entry points are hidden while this is true.
///
/// Currently DISABLED — every account, demo included, sees the full app with
/// all payment UI. Restore the commented line below to bring the hiding back;
/// all the call sites already read this provider. Defaults to `false` until
/// `/users/me` resolves, so payment UI never appears and then vanishes.
final isDemoAccountProvider = Provider<bool>((ref) {
  return false;
  // return ref.watch(currentUserProvider).valueOrNull?.isDemo ?? false;
});
