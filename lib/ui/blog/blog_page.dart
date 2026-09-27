import 'package:ai_teacher/core/auth/data/auth_session.dart';
import 'package:ai_teacher/ui/shared/widget/tab_web_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BlogPage extends ConsumerWidget {
  const BlogPage({super.key});

  static const _baseUrl = 'https://app-blog.myteacher.uz';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authSessionProvider).currentUserId ?? '';
    return TabWebView(url: '$_baseUrl?uid=${Uri.encodeQueryComponent(userId)}');
  }
}
