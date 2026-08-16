import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/push/domain/entities/push_send_result.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:flutter/material.dart';

/// Sends a push notification (notification-only) to every registered user.
/// Announcement content itself is managed on the Announcements page; this is a
/// standalone broadcast composer.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  PushSendResult? _result;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'A title is required.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _result = null;
    });
    final result =
        await sl<PushRepository>().sendToAll(title: title, message: message);
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _sending = false;
        _error = failure.message;
      }),
      (r) => setState(() {
        _sending = false;
        _result = r;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const PageHeader(
            title: 'Send Notification',
            subtitle: 'Push an instant notification to every user\'s device',
          ),
          const SizedBox(height: 24),
          GlassCard(
            padding: const EdgeInsets.all(20),
            radius: 16,
            child: SizedBox(
              width: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Notification only — no announcement card is created. Use the '
                    'Announcements page to publish a card for the app\'s home feed.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      height: 1.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  GlassTextField(
                    label: 'Title',
                    controller: _titleController,
                    hint: 'e.g. Congress app update',
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Message',
                    controller: _messageController,
                    hint: 'The notification body text',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      GlassButton(
                        label: 'Send to all users',
                        icon: Icons.send_outlined,
                        loading: _sending,
                        onPressed: _sending ? null : _send,
                      ),
                      const SizedBox(width: 14),
                      if (_error != null)
                        Flexible(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.liveRed,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_result != null) ...[
                    const SizedBox(height: 16),
                    _ResultBanner(result: _result!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultBanner extends StatelessWidget {
  final PushSendResult result;
  const _ResultBanner({required this.result});

  @override
  Widget build(BuildContext context) {
    final sentAll = result.failure == 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: sentAll
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.goldLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sentAll
              ? AppColors.gold.withValues(alpha: 0.35)
              : AppColors.goldLight.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sentAll
                ? (result.topicSent
                    ? 'Notification sent to all subscribers'
                    : 'Notification sent to all users')
                : 'Notification sent',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textWhite,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            result.topicSent
                ? 'Broadcast delivered to all topic subscribers'
                : '${result.success} delivered · ${result.failure} failed · ${result.total} devices targeted',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
