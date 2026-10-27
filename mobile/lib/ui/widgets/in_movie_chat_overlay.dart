import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/remote_config_service.dart';

class InMovieChatMessage {
  final String id;
  final String sender;
  final String text;
  final bool isMe;
  final DateTime timestamp;

  InMovieChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.isMe,
    required this.timestamp,
  });
}

class InMovieChatOverlay extends StatelessWidget {
  final List<InMovieChatMessage> messages;

  const InMovieChatOverlay({super.key, required this.messages});

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();

    // Display up to the last 3 messages stacked gently
    final visibleMessages = messages.length > 3 ? messages.sublist(messages.length - 3) : messages;

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: visibleMessages.map((msg) {
          return _SingleMessageBubble(key: ValueKey(msg.id), message: msg);
        }).toList(),
      ),
    );
  }
}

class _SingleMessageBubble extends StatelessWidget {
  final InMovieChatMessage message;

  const _SingleMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 250),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - opacity)),
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.78),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isMe
                ? AppTheme.primaryRose.withOpacity(0.6)
                : AppTheme.lavenderAccent.withOpacity(0.6),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${message.sender}: ',
                style: TextStyle(
                  color: message.isMe ? AppTheme.primaryRose : AppTheme.lavenderAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              TextSpan(
                text: message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class InMovieChatSheet extends StatefulWidget {
  final String partnerName;
  final ValueChanged<String> onSendMessage;

  const InMovieChatSheet({
    super.key,
    required this.partnerName,
    required this.onSendMessage,
  });

  static Future<void> show(
    BuildContext context, {
    required String partnerName,
    required ValueChanged<String> onSendMessage,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => InMovieChatSheet(
        partnerName: partnerName,
        onSendMessage: onSendMessage,
      ),
    );
  }

  @override
  State<InMovieChatSheet> createState() => _InMovieChatSheetState();
}

class _InMovieChatSheetState extends State<InMovieChatSheet> {
  final TextEditingController _controller = TextEditingController();

  List<String> get quickPhrases => RemoteConfigService.quickPhrases;

  void _send(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    widget.onSendMessage(trimmed);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface.withOpacity(0.96),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border(
            top: BorderSide(color: AppTheme.primaryRose.withOpacity(0.4), width: 1.5),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, size: 16, color: AppTheme.primaryRose),
                const SizedBox(width: 8),
                Text(
                  'Whisper to ${widget.partnerName}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Quick romantic presets
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: quickPhrases.map((phrase) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(phrase, style: const TextStyle(fontSize: 12, color: Colors.white)),
                      backgroundColor: AppTheme.surfaceLight,
                      side: BorderSide(color: AppTheme.primaryRose.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onPressed: () => _send(phrase),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Text Input Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 13),
                      filled: true,
                      fillColor: AppTheme.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _send(val),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _send(_controller.text),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: const Icon(Icons.send_rounded, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
