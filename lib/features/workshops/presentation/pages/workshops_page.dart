import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/action_feedback.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/core/widgets/image_upload_field.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop.dart';
import 'package:afric_eg_admin_panel/features/workshops/domain/entities/workshop_session.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_bloc.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_event.dart';
import 'package:afric_eg_admin_panel/features/workshops/presentation/bloc/workshop_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class WorkshopsPage extends StatelessWidget {
  const WorkshopsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<WorkshopBloc>(),
      child: const _WorkshopsView(),
    );
  }
}

class _WorkshopsView extends StatelessWidget {
  const _WorkshopsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) {
        final busy = state.isLoading || state.isSaving;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Workshops',
                subtitle: 'Manage pre-congress workshops and their sessions',
                trailing: GlassButton(
                  label: 'New Workshop',
                  icon: Icons.add,
                  loading: state.isSaving,
                  onPressed: busy ? null : () => _openEditor(context),
                ),
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.workshops.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.workshops.isEmpty)
                const EmptyState(message: 'No workshops yet.')
              else ...[
                if (busy)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 14),
                    child: LinearProgressIndicator(
                      minHeight: 3,
                      color: AppColors.gold,
                      backgroundColor: AppColors.glassBorder,
                    ),
                  ),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.workshops
                      .map(
                        (w) => _WorkshopCard(
                          workshop: w,
                          enabled: !busy,
                          onEdit: () => _openEditor(context, workshop: w),
                          onDelete: () => _confirmDelete(context, w),
                          onSessions: () => _openSessions(context, w),
                        ),
                      )
                      .toList(),
                ),
              ],
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

  Future<void> _openEditor(BuildContext context, {Workshop? workshop}) async {
    final isNew = workshop == null;
    final bloc = context.read<WorkshopBloc>();
    final result = await showDialog<Workshop>(
      context: context,
      builder: (_) => _WorkshopDialog(workshop: workshop),
    );
    if (result == null || !context.mounted) return;
    await runActionWithFeedback(
      context: context,
      stream: bloc.stream,
      isComplete: (WorkshopState s) => !s.isSaving,
      errorOf: (WorkshopState s) => s.error,
      dispatch: () => bloc.add(SaveWorkshopEvent(result, isNew: isNew)),
      loadingMessage: isNew ? 'Creating workshop…' : 'Saving workshop…',
      successTitle: isNew ? 'Workshop created' : 'Workshop saved',
      successMessage: isNew
          ? 'The workshop was added.'
          : 'The workshop was updated.',
      errorTitle: 'Could not save workshop',
    );
  }

  void _openSessions(BuildContext context, Workshop w) {
    final bloc = context.read<WorkshopBloc>();
    bloc.add(LoadWorkshopSessionsEvent(w.id));
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _WorkshopSessionsDialog(workshop: w),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Workshop w) async {
    final bloc = context.read<WorkshopBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Delete workshop?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
        content: Text(
          w.title,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.liveRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await runActionWithFeedback(
      context: context,
      stream: bloc.stream,
      isComplete: (WorkshopState s) => !s.isSaving,
      errorOf: (WorkshopState s) => s.error,
      dispatch: () => bloc.add(DeleteWorkshopEvent(w.id)),
      loadingMessage: 'Deleting workshop…',
      successTitle: 'Workshop deleted',
      successMessage: '${w.title} was removed.',
      errorTitle: 'Could not delete workshop',
    );
  }
}

class _WorkshopCard extends StatelessWidget {
  final Workshop workshop;
  final bool enabled;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSessions;

  const _WorkshopCard({
    required this.workshop,
    this.enabled = true,
    required this.onEdit,
    required this.onDelete,
    required this.onSessions,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      radius: 16,
      child: SizedBox(
        width: 360,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: SizedBox(
                height: 150,
                width: double.infinity,
                child: _WorkshopCover(imageUrl: workshop.imageURL),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workshop.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    [
                      if (workshop.day?.isNotEmpty == true) workshop.day!,
                      workshop.location.isNotEmpty ? workshop.location : null,
                    ].whereType<String>().join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    [
                      DateFormat('MMMM d, y').format(workshop.startDate),
                      if (workshop.price != null && workshop.price!.isNotEmpty)
                        workshop.price!,
                    ].join(' · '),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      GlassButton(
                        label: 'Sessions',
                        icon: Icons.menu_book_outlined,
                        onPressed: enabled ? onSessions : null,
                      ),
                      const Spacer(),
                      GhostIconButton(
                        icon: Icons.edit_outlined,
                        color: enabled ? null : AppColors.textDisabled,
                        onPressed: enabled ? onEdit : null,
                      ),
                      const SizedBox(width: 8),
                      GhostIconButton(
                        icon: Icons.delete_outline,
                        color: enabled
                            ? AppColors.liveRedLight
                            : AppColors.textDisabled,
                        onPressed: enabled ? onDelete : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkshopCover extends StatelessWidget {
  final String? imageUrl;
  const _WorkshopCover({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;
    if (url == null || url.isEmpty) {
      return _fallback();
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.darkBase],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.school_outlined,
          size: 34,
          color: AppColors.goldLight,
        ),
      ),
    );
  }
}

class _WorkshopDialog extends StatefulWidget {
  final Workshop? workshop;

  const _WorkshopDialog({this.workshop});

  @override
  State<_WorkshopDialog> createState() => _WorkshopDialogState();
}

class _WorkshopDialogState extends State<_WorkshopDialog> {
  late final TextEditingController _title;
  late final TextEditingController _location;
  late final TextEditingController _price;
  late DateTime _startDate;
  late DateTime _endDate;
  late final TextEditingController _day;
  late final TextEditingController _description;
  late final TextEditingController _imageURL;
  late final TextEditingController _program;
  late final String _workshopId;

  @override
  void initState() {
    super.initState();
    final w = widget.workshop;
    _workshopId = w?.id ?? Ids.generate();
    _title = TextEditingController(text: w?.title ?? '');
    _location = TextEditingController(text: w?.location ?? '');
    _price = TextEditingController(text: w?.price ?? '');
    _startDate = w?.startDate ?? DateTime(2026, 9, 1);
    _endDate = w?.endDate ?? DateTime(2026, 9, 2);
    _day = TextEditingController(text: w?.day ?? '');
    _description = TextEditingController(text: w?.description ?? '');
    _imageURL = TextEditingController(text: w?.imageURL ?? '');
    _program = TextEditingController(text: w?.program ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _price.dispose();
    _day.dispose();
    _description.dispose();
    _imageURL.dispose();
    _program.dispose();
    super.dispose();
  }

  String? _optional(TextEditingController c) =>
      c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _pickDate({required bool isStart}) async {
    final current = isStart ? _startDate : _endDate;
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2025),
      lastDate: DateTime(2027),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  void _save() {
    final workshop = Workshop(
      id: widget.workshop?.id ?? _workshopId,
      title: _title.text.trim(),
      location: _location.text.trim(),
      price: _optional(_price),
      startDate: _startDate,
      endDate: _endDate,
      day: _optional(_day),
      description: _optional(_description),
      imageURL: _optional(_imageURL),
      program: _optional(_program),
    );
    Navigator.pop(context, workshop);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: Text(
        widget.workshop == null ? 'New Workshop' : 'Edit Workshop',
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 480,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GlassTextField(
                label: 'Title',
                controller: _title,
                hint: 'Ultrasound in OB/GYN Emergencies',
              ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    label: 'Location',
                    controller: _location,
                    hint: 'Princess Fatima Academy',
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GlassTextField(
                          label: 'Day',
                          controller: _day,
                          hint: 'Day 1',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GlassTextField(
                          label: 'Price',
                          controller: _price,
                          hint: 'EGP 1500',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'Start date',
                          value: _startDate,
                          onTap: () => _pickDate(isStart: true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _DateField(
                          label: 'End date',
                          value: _endDate,
                          onTap: () => _pickDate(isStart: false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ImageUploadField(
                    urlController: _imageURL,
                    objectId: _workshopId,
                    pathPrefix: 'workshop',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    label: 'Image URL',
                    controller: _imageURL,
                    hint: 'https://…',
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    label: 'Description',
                    controller: _description,
                    hint: 'Short workshop overview',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  GlassTextField(
                    label: 'Program',
                    controller: _program,
                    hint: 'Full program details',
                    maxLines: 4,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassButton(
              label: 'Save',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        );
  }
}

class _WorkshopSessionsDialog extends StatelessWidget {
  final Workshop workshop;

  const _WorkshopSessionsDialog({required this.workshop});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkshopBloc, WorkshopState>(
      builder: (context, state) {
        final isCurrent = state.selectedWorkshopId == workshop.id;
        final sessions = isCurrent ? state.sessions : const <WorkshopSession>[];
        final loading = isCurrent && state.isLoading;
        final busy = loading || (isCurrent && state.isSaving);
        return Dialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 520),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          workshop.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(color: AppColors.glassBorder, height: 1),
                Expanded(
                  child: loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                          ),
                        )
                      : (isCurrent && state.error != null)
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 28,
                                  color: AppColors.liveRed,
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  state.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.liveRed,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                GlassButton(
                                  label: 'Retry',
                                  icon: Icons.refresh,
                                  onPressed: () =>
                                      context.read<WorkshopBloc>().add(
                                        LoadWorkshopSessionsEvent(workshop.id),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : sessions.isEmpty
                      ? const EmptyState(
                          message: 'No sessions for this workshop.',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: sessions.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final s = sessions[index];
                            return GlassCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: s.isBreak
                                          ? AppColors.pinnedGold.withValues(
                                              alpha: 0.15,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.25,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${DateFormat.Hm().format(s.startTime)}\n${DateFormat.Hm().format(s.endTime)}',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textWhite,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.isBreak ? 'Break' : s.topic,
                                          style: const TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textWhite,
                                          ),
                                        ),
                                        if (!s.isBreak) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            s.speaker,
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              color: AppColors.textTertiary,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  if (s.dayLabel != null)
                                    StatusBadge(
                                      label: s.dayLabel!,
                                      color: AppColors.accent,
                                    ),
                                  const SizedBox(width: 8),
                                  GhostIconButton(
                                    icon: Icons.edit_outlined,
                                    onPressed: busy
                                        ? null
                                        : () => _openSessionEditor(
                                            context,
                                            workshopId: workshop.id,
                                            session: s,
                                          ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                const Divider(color: AppColors.glassBorder, height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Spacer(),
                      GlassButton(
                        label: 'Add Session',
                        icon: Icons.add,
                        loading: isCurrent && state.isSaving,
                        onPressed: busy
                            ? null
                            : () => _openSessionEditor(
                                context,
                                workshopId: workshop.id,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openSessionEditor(
    BuildContext context, {
    required String workshopId,
    WorkshopSession? session,
  }) async {
    final isNew = session == null;
    final bloc = context.read<WorkshopBloc>();
    final result = await showDialog<WorkshopSession>(
      context: context,
      builder: (_) =>
          _SessionEditorDialog(workshopId: workshopId, session: session),
    );
    if (result == null || !context.mounted) return;
    await runActionWithFeedback(
      context: context,
      stream: bloc.stream,
      isComplete: (WorkshopState s) => !s.isSaving,
      errorOf: (WorkshopState s) => s.error,
      dispatch: () => bloc.add(
        SaveWorkshopSessionEvent(workshopId, result, isNew: isNew),
      ),
      loadingMessage: isNew ? 'Creating session…' : 'Saving session…',
      successTitle: isNew ? 'Session created' : 'Session saved',
      successMessage: isNew
          ? 'The session was added to the workshop.'
          : 'The session was updated.',
      errorTitle: 'Could not save session',
    );
  }
}

class _SessionEditorDialog extends StatefulWidget {
  final String workshopId;
  final WorkshopSession? session;

  const _SessionEditorDialog({required this.workshopId, this.session});

  @override
  State<_SessionEditorDialog> createState() => _SessionEditorDialogState();
}

class _SessionEditorDialogState extends State<_SessionEditorDialog> {
  late DateTime _startTime;
  late DateTime _endTime;
  late final TextEditingController _topic;
  late final TextEditingController _speaker;
  late final TextEditingController _dayLabel;
  late bool _isBreak;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _startTime = s?.startTime ?? DateTime(2026, 9, 1, 9, 0);
    _endTime = s?.endTime ?? DateTime(2026, 9, 1, 10, 0);
    _topic = TextEditingController(text: s?.topic ?? '');
    _speaker = TextEditingController(text: s?.speaker ?? '');
    _dayLabel = TextEditingController(text: s?.dayLabel ?? '');
    _isBreak = s?.isBreak ?? false;
  }

  @override
  void dispose() {
    _topic.dispose();
    _speaker.dispose();
    _dayLabel.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) return;
    setState(() {
      final value = DateTime(
        current.year,
        current.month,
        current.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  void _save() {
    final session = WorkshopSession(
      id: widget.session?.id ?? Ids.generate(),
      startTime: _startTime,
      endTime: _endTime,
      topic: _topic.text.trim(),
      speaker: _speaker.text.trim(),
      isBreak: _isBreak,
      dayLabel: _dayLabel.text.trim().isEmpty ? null : _dayLabel.text.trim(),
    );
    Navigator.pop(context, session);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: Text(
        widget.session == null ? 'New Session' : 'Edit Session',
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
                  children: [
                    Expanded(
                      child: _TimeField(
                        label: 'Start time',
                        value: _startTime,
                        onTap: () => _pickTime(isStart: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeField(
                        label: 'End time',
                        value: _endTime,
                        onTap: () => _pickTime(isStart: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  label: 'Topic',
                  controller: _topic,
                  hint: 'Session topic',
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  label: 'Speaker',
                  controller: _speaker,
                  hint: 'Dr. Name',
                ),
                const SizedBox(height: 12),
                GlassTextField(
                  label: 'Day label (optional)',
                  controller: _dayLabel,
                  hint: 'Day 1',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Is a break',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const Spacer(),
                    Switch(
                      value: _isBreak,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isBreak = v),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            GlassButton(
              label: 'Save',
              icon: Icons.save_outlined,
              onPressed: _save,
            ),
          ],
        );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, y').format(value),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  final String label;
  final DateTime value;
  final VoidCallback onTap;

  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    DateFormat.jm().format(value),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
