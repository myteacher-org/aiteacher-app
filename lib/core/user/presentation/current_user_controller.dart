import 'package:ai_teacher/core/user/data/user_dtos.dart';
import 'package:ai_teacher/core/user/data/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentUserProvider = FutureProvider<User>((ref) {
  return ref.watch(userRepositoryProvider).getMe();
});
