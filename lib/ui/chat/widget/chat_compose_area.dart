import 'package:ai_teacher/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';

class ChatComposeArea extends StatelessWidget {
  const ChatComposeArea({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onAttach,
    this.attachEnabled = true,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool attachEnabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0x12000000), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: SafeArea(
        top: false,
        child: _ComposeRow(
          controller: controller,
          onSend: onSend,
          onAttach: onAttach,
          attachEnabled: attachEnabled,
        ),
      ),
    );
  }
}

class _ComposeRow extends StatelessWidget {
  const _ComposeRow({
    required this.controller,
    required this.onSend,
    required this.onAttach,
    required this.attachEnabled,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool attachEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _AttachButton(onTap: onAttach, enabled: attachEnabled),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAE4),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              style: const TextStyle(
                color: Color(0xFF333333),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: l10n.chatMessageHint,
                hintStyle: const TextStyle(
                  color: Color(0xFFBBBBBB),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _SendButton(onTap: onSend),
      ],
    );
  }
}

class _AttachButton extends StatelessWidget {
  const _AttachButton({required this.onTap, required this.enabled});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFEDEAE4),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(13),
        child: SizedBox(
          width: 42,
          height: 42,
          child: enabled
              ? const Icon(
                  Icons.attach_file_rounded,
                  color: Color(0xFF555555),
                  size: 18,
                )
              : const SizedBox(
                  width: 16,
                  height: 16,
                  child: Center(
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F172A),
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(Icons.send_rounded, color: Colors.white, size: 16),
        ),
      ),
    );
  }
}
