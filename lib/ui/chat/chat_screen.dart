import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/app/theme/app_colors.dart';
import 'package:ai_teacher/core/chat/data/chat_dtos.dart' show ChatMessage;
import 'package:ai_teacher/core/chat/presentation/chat_room_controller.dart';
import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:ai_teacher/ui/chat/chat_data.dart' as ui;
import 'package:ai_teacher/ui/chat/widget/activity_date_separator.dart';
import 'package:ai_teacher/ui/chat/widget/activity_item_view.dart';
import 'package:ai_teacher/ui/chat/widget/chat_compose_area.dart';
import 'package:ai_teacher/ui/chat/widget/chat_header.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Must match the backend's accepted set exactly: any image/*, plus
// application/pdf, .doc, .docx, .xls, .xlsx — anything else is rejected
// with a 400.
const _kAttachmentExtensions = [
  'jpg',
  'jpeg',
  'png',
  'gif',
  'webp',
  'heic',
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
];

const _kMaxAttachmentBytes = 10 * 1024 * 1024;

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _PendingAttachmentBanner extends StatelessWidget {
  const _PendingAttachmentBanner({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFF1F5F9),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$name yuborilmoqda…',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _composeController = TextEditingController();
  String? _lastErrorShown;

  static const _meColors = [Color(0xFF0D9488), Color(0xFF0F766E)];

  List<String> _months(AppLocalizations l10n) => [
    l10n.chatMonthJanuary,
    l10n.chatMonthFebruary,
    l10n.chatMonthMarch,
    l10n.chatMonthApril,
    l10n.chatMonthMay,
    l10n.chatMonthJune,
    l10n.chatMonthJuly,
    l10n.chatMonthAugust,
    l10n.chatMonthSeptember,
    l10n.chatMonthOctober,
    l10n.chatMonthNovember,
    l10n.chatMonthDecember,
  ];

  @override
  void initState() {
    super.initState();
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: false,
      badge: false,
      sound: false,
    );
  }

  @override
  void dispose() {
    FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    _composeController.dispose();
    super.dispose();
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.goNamed(AppRoute.main.name);
    }
  }

  Future<void> _onSend() async {
    final text = _composeController.text.trim();
    if (text.isEmpty) return;
    final ok = await ref.read(chatRoomControllerProvider.notifier).send(text);
    if (!mounted || !ok) return;
    _composeController.clear();
    FocusScope.of(context).unfocus();
  }

  Future<void> _onAttach() async {
    if (ref.read(chatRoomControllerProvider).sending) return;
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _kAttachmentExtensions,
    );
    final files = result?.files;
    final file = (files != null && files.isNotEmpty) ? files.first : null;
    if (file == null || file.path == null || !mounted) return;
    if (file.size > _kMaxAttachmentBytes) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Fayl hajmi 10 MB dan oshmasligi kerak'),
          ),
        );
      return;
    }
    await ref
        .read(chatRoomControllerProvider.notifier)
        .sendAttachment(file.path!, file.name);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(chatRoomControllerProvider);
    final currentUserId = ref.watch(currentUserIdProvider);

    if (state.error != null && state.error != _lastErrorShown) {
      _lastErrorShown = state.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error!)));
      });
    }

    final groups = _buildGroups(state.messages, currentUserId, l10n);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ChatHeader(
                title: l10n.chatTitle,
                subtitle: l10n.chatSubtitle,
                onClose: _onBack,
              ),
              Expanded(child: _buildBody(state, groups, l10n)),
              if (state.pendingAttachmentName != null)
                _PendingAttachmentBanner(name: state.pendingAttachmentName!),
              ChatComposeArea(
                controller: _composeController,
                onSend: _onSend,
                onAttach: _onAttach,
                attachEnabled: !state.sending,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    ChatRoomState state,
    List<ui.ActivityGroup> groups,
    AppLocalizations l10n,
  ) {
    if (state.loading) {
      return const Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      );
    }
    if (groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            state.error ?? l10n.chatEmptyState,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8A8580),
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.55,
            ),
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: groups.length,
      reverse: true,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.only(top: index == 0 ? 4 : 8),
              child: ActivityDateSeparator(label: group.dateLabel),
            ),
            for (final item in group.items)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ActivityItemView(item: item),
              ),
          ],
        );
      },
    );
  }

  List<ui.ActivityGroup> _buildGroups(
    List<ChatMessage> messages,
    String? currentUserId,
    AppLocalizations l10n,
  ) {
    final filtered = messages;
    if (filtered.isEmpty) return const [];

    final asc = filtered.reversed.toList();
    final byKey = <String, List<ChatMessage>>{};
    final order = <String>[];
    for (final m in asc) {
      final key = _dayKey(m.sentAt);
      byKey
          .putIfAbsent(key, () {
            order.add(key);
            return <ChatMessage>[];
          })
          .add(m);
    }

    return order.reversed.map((key) {
      final dayMessages = byKey[key]!;
      return ui.ActivityGroup(
        dateLabel: _dateLabel(dayMessages.first.sentAt, l10n),
        items: [
          for (final m in dayMessages) _toActivityItem(m, currentUserId, l10n),
        ],
      );
    }).toList();
  }

  ui.ActivityItem _toActivityItem(
    ChatMessage msg,
    String? currentUserId,
    AppLocalizations l10n,
  ) {
    final mine = currentUserId != null && msg.authorUserId == currentUserId;
    return ui.ActivityItem(
      authorName: mine ? l10n.chatYou : msg.authorFullName,
      initials: mine ? 'S' : _initials(msg.authorFullName),
      avatarColors: mine ? _meColors : _colorsFor(msg.authorUserId),
      role: _roleLabel(msg.authorRole, l10n),
      time: _formatTime(msg.sentAt),
      body: msg.text,
      mine: mine,
      attachmentUrl: msg.fileUrl,
      attachmentName: msg.fileName,
      attachmentMimeType: msg.fileType,
    );
  }

  String _roleLabel(String role, AppLocalizations l10n) => switch (role) {
    'mentor' => l10n.chatRoleMentor,
    'admin' => l10n.chatRoleAdmin,
    _ => l10n.chatRoleStudent,
  };

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '?';
  }

  List<Color> _colorsFor(String userId) {
    const palette = <List<Color>>[
      [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
      [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
      [Color(0xFFF59E0B), Color(0xFFD97706)],
      [Color(0xFFF472B6), Color(0xFFEC4899)],
      [Color(0xFF64748B), Color(0xFF334155)],
      [Color(0xFF0D9488), Color(0xFF059669)],
    ];
    if (userId.isEmpty) return palette.first;
    final hash = userId.codeUnits.fold<int>(0, (a, b) => a + b);
    return palette[hash % palette.length];
  }

  String _formatTime(DateTime d) {
    final local = d.toLocal();
    final h = local.hour.toString().padLeft(2, '0');
    final m = local.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dayKey(DateTime d) {
    final l = d.toLocal();
    return '${l.year}-${l.month}-${l.day}';
  }

  String _dateLabel(DateTime d, AppLocalizations l10n) {
    final local = d.toLocal();
    final today = DateTime.now();
    final months = _months(l10n);
    final dayMonth = '${local.day}-${months[local.month - 1]}';
    if (_sameDay(local, today)) {
      return l10n.chatDateToday(dayMonth);
    }
    final yest = today.subtract(const Duration(days: 1));
    if (_sameDay(local, yest)) {
      return l10n.chatDateYesterday(dayMonth);
    }
    return dayMonth;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
