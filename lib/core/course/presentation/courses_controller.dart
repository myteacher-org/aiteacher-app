import 'package:ai_teacher/core/course/data/course_dtos.dart';
import 'package:ai_teacher/core/course/data/course_repository.dart';
import 'package:ai_teacher/core/user/presentation/current_user_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CoursesState {
  const CoursesState({this.mine = const [], this.available = const []});

  final List<Course> mine;

  /// Active courses the user is not enrolled in.
  final List<Course> available;
}

class CoursesController extends AutoDisposeAsyncNotifier<CoursesState> {
  @override
  Future<CoursesState> build() async {
    final repo = ref.watch(courseRepositoryProvider);
    final results = await Future.wait([repo.listMine(), repo.listActive()]);
    final mine = results[0];
    final enrolledIds = mine.map((c) => c.id).toSet();
    final available = results[1]
        .where((c) => !enrolledIds.contains(c.id))
        .toList();
    return CoursesState(mine: mine, available: available);
  }

  Future<void> refresh() async {
    // Pull-to-refresh should also pick up a subscription/plan change, since
    // course access is gated on the cached currentUserProvider value.
    ref.invalidate(currentUserProvider);
    ref.invalidateSelf();
    await future;
  }
}

final coursesControllerProvider =
    AutoDisposeAsyncNotifierProvider<CoursesController, CoursesState>(
      CoursesController.new,
    );
