import 'package:ai_teacher/app/data/network_config.dart';
import 'package:ai_teacher/app/router/app_router.dart';
import 'package:ai_teacher/ui/chat/chat_data.dart';
import 'package:ai_teacher/ui/chat/widget/activity_avatar.dart';
import 'package:ai_teacher/ui/chat/widget/image_viewer_screen.dart';
import 'package:ai_teacher/ui/courses/course_web_screen.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class ActivityItemView extends StatelessWidget {
  const ActivityItemView({super.key, required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return item.mine ? _MineBubble(item: item) : _TheirBubble(item: item);
  }
}

class _TheirBubble extends StatelessWidget {
  const _TheirBubble({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ActivityAvatar(initials: item.initials, colors: item.avatarColors),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      item.authorName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF222222),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  _RoleChip(label: item.role),
                ],
              ),
              const SizedBox(height: 5),
              _Bubble(
                body: item.body,
                time: item.time,
                mine: false,
                attachmentUrl: item.attachmentUrl,
                attachmentName: item.attachmentName,
                attachmentMimeType: item.attachmentMimeType,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MineBubble extends StatelessWidget {
  const _MineBubble({required this.item});

  final ActivityItem item;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.sizeOf(context).width * 0.72;
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _Bubble(
          body: item.body,
          time: item.time,
          mine: true,
          attachmentUrl: item.attachmentUrl,
          attachmentName: item.attachmentName,
          attachmentMimeType: item.attachmentMimeType,
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.body,
    required this.time,
    required this.mine,
    this.attachmentUrl,
    this.attachmentName,
    this.attachmentMimeType,
  });

  final String body;
  final String time;
  final bool mine;
  final String? attachmentUrl;
  final String? attachmentName;
  final String? attachmentMimeType;

  bool get _hasAttachment => attachmentUrl != null && attachmentUrl!.isNotEmpty;
  bool get _isImage => (attachmentMimeType ?? '').startsWith('image/');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        _hasAttachment && _isImage ? 6 : 13,
        _hasAttachment && _isImage ? 6 : 10,
        _hasAttachment && _isImage ? 6 : 13,
        8,
      ),
      decoration: BoxDecoration(
        color: mine ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(14),
          topRight: Radius.circular(mine ? 4 : 14),
          bottomLeft: const Radius.circular(14),
          bottomRight: const Radius.circular(14),
        ),
        border: mine
            ? null
            : Border.all(color: const Color(0x0D000000), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hasAttachment && _isImage)
            _AttachmentImage(url: attachmentUrl!)
          else if (_hasAttachment)
            _AttachmentFileChip(
              url: attachmentUrl!,
              name: attachmentName ?? 'Fayl',
              mine: mine,
            ),
          if (_hasAttachment) const SizedBox(height: 6),
          if (body.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: _hasAttachment && _isImage ? 7 : 0,
              ),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _LinkifiedText(
                  text: body,
                  style: TextStyle(
                    color: mine ? Colors.white : const Color(0xFF333333),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.55,
                  ),
                  linkColor: mine ? Colors.white : const Color(0xFF2563EB),
                ),
              ),
            ),
          if (body.isNotEmpty) const SizedBox(height: 4),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: _hasAttachment && _isImage && body.isEmpty ? 7 : 0,
            ),
            child: Text(
              time,
              style: TextStyle(
                color: mine
                    ? Colors.white.withValues(alpha: 0.45)
                    : const Color(0xFFBBBBBB),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final _urlPattern = RegExp(r'(https?:\/\/[^\s]+)');

/// Renders [text] with any URLs made tappable. A tap opens the link inside
/// the app's own webview ([CourseWebScreen] via `AppRoute.linkWeb`) instead
/// of handing off to an external browser — this is how mentors share
/// lesson.myteacher.uz lesson links in chat.
class _LinkifiedText extends StatefulWidget {
  const _LinkifiedText({
    required this.text,
    required this.style,
    required this.linkColor,
  });

  final String text;
  final TextStyle style;
  final Color linkColor;

  @override
  State<_LinkifiedText> createState() => _LinkifiedTextState();
}

class _LinkifiedTextState extends State<_LinkifiedText> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();

    final matches = _urlPattern.allMatches(widget.text);
    if (matches.isEmpty) {
      return Text(widget.text, style: widget.style);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;
    for (final match in matches) {
      if (match.start > cursor) {
        spans.add(TextSpan(text: widget.text.substring(cursor, match.start)));
      }
      final url = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => context.pushNamed(
          AppRoute.linkWeb.name,
          extra: LinkWebArgs(title: '', url: url),
        );
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: TextStyle(
            color: widget.linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: recognizer,
        ),
      );
      cursor = match.end;
    }
    if (cursor < widget.text.length) {
      spans.add(TextSpan(text: widget.text.substring(cursor)));
    }

    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}

class _AttachmentImage extends StatelessWidget {
  const _AttachmentImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final resolved = NetworkConfig.resolveStatic(url);
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ImageViewerScreen(url: resolved)),
        ),
        child: SizedBox(
          width: 200,
          height: 200,
          child: Image.network(
            resolved,
            fit: BoxFit.cover,
            // Reserves the full frame immediately instead of collapsing to
            // a thin row until the image finishes downloading.
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: const Color(0xFFF1F5F9),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                ),
              );
            },
            errorBuilder: (_, _, _) => Container(
              color: const Color(0xFFF1F5F9),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachmentFileChip extends StatelessWidget {
  const _AttachmentFileChip({
    required this.url,
    required this.name,
    required this.mine,
  });

  final String url;
  final String name;
  final bool mine;

  @override
  Widget build(BuildContext context) {
    final fg = mine ? Colors.white : const Color(0xFF333333);
    return GestureDetector(
      onTap: () => launchUrl(
        Uri.parse(NetworkConfig.resolveStatic(url)),
        mode: LaunchMode.externalApplication,
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: mine
              ? Colors.white.withValues(alpha: 0.1)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file_rounded, size: 18, color: fg),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (label) {
      'Mentor' => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
      'Admin' => (const Color(0xFFEDE9FE), const Color(0xFF6D28D9)),
      _ => (const Color(0xFFF1F5F9), const Color(0xFF64748B)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
