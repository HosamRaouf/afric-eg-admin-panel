import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/announcements/domain/entities/announcement.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_bloc.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_event.dart';
import 'package:afric_eg_admin_panel/features/announcements/presentation/bloc/announcement_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AnnouncementsPage extends StatelessWidget {
  const AnnouncementsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AnnouncementBloc>(),
      child: const _AnnouncementsView(),
    );
  }
}

class _AnnouncementsView extends StatelessWidget {
  const _AnnouncementsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnnouncementBloc, AnnouncementState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Announcements',
                subtitle:
                    'Announcements push to all users and appear on the app\'s home feed',
                trailing: GlassButton(
                  label: 'New Announcement',
                  icon: Icons.add,
                  onPressed: () => _openEditor(context),
                ),
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.announcements.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.announcements.isEmpty)
                const EmptyState(message: 'No announcements yet.')
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.announcements
                      .map(
                        (a) => _AnnouncementCard(
                          announcement: a,
                          onEdit: () => _openEditor(context, announcement: a),
                          onDelete: () => _confirmDelete(context, a),
                        ),
                      )
                      .toList(),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.liveRed,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openEditor(BuildContext context, {Announcement? announcement}) {
    final bloc = context.read<AnnouncementBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _AnnouncementDialog(announcement: announcement),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Announcement a) {
    final bloc = context.read<AnnouncementBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: const Text(
            'Delete announcement?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: Text(
            a.title,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                bloc.add(DeleteAnnouncementEvent(a.id));
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.liveRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AnnouncementCard({
    required this.announcement,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 320,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: const Icon(
                    Icons.campaign_outlined,
                    size: 16,
                    color: AppColors.highlight,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        announcement.title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        DateFormat.yMMMd().add_jm().format(
                          announcement.createdAt,
                        ),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (announcement.unread)
                  const StatusBadge(
                    label: 'UNREAD',
                    color: AppColors.liveRedLight,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              announcement.preview,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  announcement.icon,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: AppColors.accent,
                  ),
                ),
                const Spacer(),
                GhostIconButton(icon: Icons.edit_outlined, onPressed: onEdit),
                const SizedBox(width: 8),
                GhostIconButton(
                  icon: Icons.delete_outline,
                  color: AppColors.liveRedLight,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementDialog extends StatefulWidget {
  final Announcement? announcement;

  const _AnnouncementDialog({this.announcement});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  late final TextEditingController _title;
  late final TextEditingController _preview;
  late final TextEditingController _body;
  late final TextEditingController _icon;
  DateTime _createdAt = DateTime.now();
  bool _unread = false;

  @override
  void initState() {
    super.initState();
    final a = widget.announcement;
    _title = TextEditingController(text: a?.title ?? '');
    _preview = TextEditingController(text: a?.preview ?? '');
    _body = TextEditingController(text: a?.body ?? '');
    _icon = TextEditingController(text: a?.icon ?? 'bullhorn');
    _createdAt = a?.createdAt ?? DateTime.now();
    _unread = a?.unread ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    _preview.dispose();
    _body.dispose();
    _icon.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;

    final isNew = widget.announcement == null;
    final announcement = Announcement(
      id: widget.announcement?.id ?? Ids.generate(),
      icon: _icon.text.trim().isEmpty ? 'bullhorn' : _icon.text.trim(),
      title: _title.text.trim(),
      preview: _preview.text.trim(),
      body: _body.text.trim(),
      createdAt: _createdAt,
      unread: _unread,
    );
    context.read<AnnouncementBloc>().add(
      SaveAnnouncementEvent(announcement, isNew: isNew),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AnnouncementBloc, AnnouncementState>(
      listenWhen: (prev, curr) =>
          prev.isSaving && !curr.isSaving && curr.error == null,
      listener: (context, state) => Navigator.pop(context),
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            widget.announcement == null
                ? 'New Announcement'
                : 'Edit Announcement',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassTextField(
                    label: 'Title',
                    controller: _title,
                    hint: 'Room Change: Workshop A',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Preview',
                    controller: _preview,
                    hint: 'Short description shown on the home feed',
                    maxLines: 3,
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Body (full message)',
                    controller: _body,
                    hint:
                        'Full text shown in the app\'s announcements screen and push notification',
                    maxLines: 5,
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          label: 'Icon key',
                          controller: _icon,
                          hint: 'bullhorn, map-pin, utensils',
                          enabled: !state.isSaving,
                        ),
                      ),
                      const SizedBox(width: 12),
                      InkWell(
                        onTap: state.isSaving
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _createdAt,
                                  firstDate: DateTime(2026, 1, 1),
                                  lastDate: DateTime(2027, 12, 31),
                                );
                                if (date != null && mounted) {
                                  setState(() => _createdAt = date);
                                }
                              },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const Icon(
                            Icons.calendar_today_outlined,
                            size: 15,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text(
                        'Mark as unread (shows badge)',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const Spacer(),
                      Switch(
                        value: _unread,
                        activeTrackColor: AppColors.primary,
                        onChanged: state.isSaving
                            ? null
                            : (v) => setState(() => _unread = v),
                      ),
                    ],
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.liveRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            state.isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : GlassButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    onPressed: _save,
                  ),
          ],
        );
      },
    );
  }
}
