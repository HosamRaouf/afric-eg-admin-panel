import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/action_feedback.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_bloc.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_state.dart';
import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AgendaBloc>(),
      child: const _AgendaView(),
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AgendaBloc, AgendaState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Agenda',
                subtitle: 'Edit sessions and talks per day / hall track',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GlassButton(
                      label: 'Add Session Block',
                      icon: Icons.add,
                      onPressed: state.selectedDayKey == null
                          ? null
                          : () => _openEditor(
                              context,
                              dayKey: state.selectedDayKey!,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (state.days.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.days.map((day) {
                    final active = day.key == state.selectedDayKey;
                    final index = day.day - 1;
                    final dateLabel =
                        index >= 0 && index < state.eventDates.length
                        ? DateFormat(
                            'MMM d, yyyy',
                          ).format(state.eventDates[index])
                        : null;
                    return InkWell(
                      onTap: () => context.read<AgendaBloc>().add(
                        SelectDayEvent(day.key),
                      ),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: active ? AppColors.primary : AppColors.glassBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? AppColors.gold.withValues(alpha: 0.3)
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Day ${day.day} · Hall ${day.hall}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: active
                                    ? AppColors.textWhite
                                    : AppColors.textSecondary,
                              ),
                            ),
                            if (dateLabel != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                dateLabel,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: active
                                      ? AppColors.textWhite
                                      : AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
              if (state.isLoading && state.items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.items.isEmpty)
                const EmptyState(message: 'No agenda items in this track.')
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.items
                      .map(
                        (item) => _AgendaItemCard(
                          item: item,
                          onEdit: () => _openEditor(
                            context,
                            dayKey: state.selectedDayKey!,
                            item: item,
                          ),
                          onDelete: () => _confirmDelete(
                            context,
                            state.selectedDayKey!,
                            item,
                          ),
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

  Future<void> _openEditor(
    BuildContext context, {
    required String dayKey,
    AgendaItem? item,
  }) async {
    final config = await sl<AdminDataSource>().getConfig();
    if (!context.mounted) return;
    final isNew = item == null;
    final dayNum = AgendaDay.fromKey(dayKey).day;
    final dayDate = config != null && config.eventDates.isNotEmpty
        ? config.eventDate(dayNum)
        : DateTime(2026, 9, 5).add(Duration(days: dayNum - 1));
    final result = await showDialog<AgendaItem>(
      context: context,
      builder: (_) =>
          _AgendaItemDialog(dayKey: dayKey, item: item, dayDate: dayDate),
    );
    if (result == null || !context.mounted) return;
    await runActionWithFeedback(
      context: context,
      stream: context.read<AgendaBloc>().stream,
      isComplete: (AgendaState s) => !s.isSaving,
      errorOf: (AgendaState s) => s.error,
      dispatch: () => context.read<AgendaBloc>().add(
        SaveAgendaItemEvent(dayKey, result, isNew: isNew),
      ),
      loadingMessage: isNew
          ? 'Creating session block…'
          : 'Saving session block…',
      successTitle: isNew ? 'Session block created' : 'Session block saved',
      successMessage: isNew
          ? 'The session block was added to the agenda.'
          : 'The session block was updated.',
      errorTitle: 'Could not save session block',
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String dayKey,
    AgendaItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Delete agenda item?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
        content: Text(
          item.title,
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
      stream: context.read<AgendaBloc>().stream,
      isComplete: (AgendaState s) => !s.isSaving,
      errorOf: (AgendaState s) => s.error,
      dispatch: () => context.read<AgendaBloc>().add(
        DeleteAgendaItemEvent(dayKey, item.id),
      ),
      loadingMessage: 'Deleting session block…',
      successTitle: 'Session block deleted',
      successMessage: 'The session block was removed from the agenda.',
      errorTitle: 'Could not delete session block',
    );
  }
}

class _AgendaItemCard extends StatelessWidget {
  final AgendaItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AgendaItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = switch (item.type) {
      'sessionBlock' => AppColors.highlight,
      'breakBand' => AppColors.pinnedGold,
      _ => AppColors.gold,
    };
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 340,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                StatusBadge(
                  label: item.type == 'sessionBlock'
                      ? 'SESSION'
                      : item.type.toUpperCase(),
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat.jm().format(item.startTime)} – ${DateFormat.jm().format(item.endTime)}',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (item.raisedHands.isNotEmpty)
                  StatusBadge(
                    label: '✋ ${item.raisedHands.length}',
                    color: AppColors.liveRedLight,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.title,
              style: const TextStyle(
                fontFamily: 'SpaceGrotesk',
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            if (item.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                item.subtitle,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
            const SizedBox(height: 10),
            if (item.isSessionBlock)
              Text(
                '${item.talks.length} talk(s) · ${item.talks.where((t) => t.status == 'live').length} live',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.accent,
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
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

class _AgendaItemDialog extends StatefulWidget {
  final String dayKey;
  final AgendaItem? item;
  final DateTime dayDate;

  const _AgendaItemDialog({
    required this.dayKey,
    this.item,
    required this.dayDate,
  });

  @override
  State<_AgendaItemDialog> createState() => _AgendaItemDialogState();
}

class _AgendaItemDialogState extends State<_AgendaItemDialog> {
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late DateTime _startTime;
  late DateTime _endTime;
  late DateTime _dayDate;
  late String _type;
  late final List<GlobalKey<_TalkEditorState>> _talkKeys;
  late final List<Talk?> _talkInitials;

  static const _typeOptions = [
    (value: 'sessionBlock', label: 'Session', icon: Icons.menu_book_outlined),
    (value: 'breakBand', label: 'Break', icon: Icons.free_breakfast_outlined),
    (value: 'ceremony', label: 'Ceremony', icon: Icons.emoji_events_outlined),
  ];

  static const _breakIcons = [
    (emoji: '☕', label: 'Coffee', icon: Icons.free_breakfast_outlined),
    (emoji: '🍽️', label: 'Lunch', icon: Icons.lunch_dining_outlined),
  ];
  late String _breakIcon;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _subtitle = TextEditingController(text: item?.subtitle ?? '');
    _type = item?.type ?? 'sessionBlock';
    _breakIcon = _type == 'breakBand' && (item?.icon.isNotEmpty ?? false)
        ? item!.icon
        : '☕';
    _dayDate = widget.dayDate;
    _startTime = item?.startTime ?? DateTime(2026, 1, 1, 9, 0);
    _endTime = item?.endTime ?? DateTime(2026, 1, 1, 10, 0);
    _talkKeys = <GlobalKey<_TalkEditorState>>[];
    _talkInitials = <Talk?>[];
    for (final t in (item?.talks ?? const <Talk>[])) {
      _talkKeys.add(GlobalKey<_TalkEditorState>());
      _talkInitials.add(t);
    }
    if (_talkKeys.isEmpty) {
      _talkKeys.add(GlobalKey<_TalkEditorState>());
      _talkInitials.add(null);
    }
  }

  /// Applies the session's congress day date to a time-only `DateTime`
  /// (e.g. `DateTime(2026, 1, 1, 9, 30)`), producing the real `Timestamp`
  /// value stored to Firestore. Day 1 = congress start day, Day 2 = +1 day…
  DateTime _resolveToDay(DateTime t) =>
      DateTime(_dayDate.year, _dayDate.month, _dayDate.day, t.hour, t.minute);

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
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
      final value = DateTime(2026, 1, 1, time.hour, time.minute);
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  void _save() {
    final id = widget.item?.id ?? Ids.generate();
    final start = _resolveToDay(_startTime);
    final end = _resolveToDay(_endTime);

    // Breaks and ceremonies are stored as their own agenda-item type with
    // nothing but times (plus the minimal title/icon the app model requires) —
    // never as a session block with talks.
    if (_type == 'breakBand' || _type == 'ceremony') {
      Navigator.pop(
        context,
        AgendaItem(
          type: _type,
          id: id,
          title: _title.text.trim(),
          subtitle: _type == 'ceremony' ? _subtitle.text.trim() : '',
          icon: _type == 'breakBand' ? _breakIcon : '',
          startTime: start,
          endTime: end,
          talks: const [],
        ),
      );
      return;
    }

    final talks = _talkKeys
        .map((k) => k.currentState?.toTalk())
        .whereType<Talk>()
        .toList();
    final item = AgendaItem(
      type: 'sessionBlock',
      id: id,
      title: _title.text.trim(),
      startTime: start,
      endTime: end,
      talks: talks,
    );
    Navigator.pop(context, item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Text(
                    widget.item == null
                        ? 'New Session Block'
                        : 'Edit Session Block',
                    style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
                  ),
                  const Spacer(),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GlassTextField(
                      label: 'Title',
                      controller: _title,
                      hint: 'Fertility Assessment',
                    ),
                    const SizedBox(height: 12),
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
                    const SizedBox(height: 18),
                    const Text(
                      'Type',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.04,
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: _typeOptions.map((o) {
                        final selected = _type == o.value;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _TypeChip(
                            label: o.label,
                            icon: o.icon,
                            selected: selected,
                            onTap: () => setState(() => _type = o.value),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    if (_type == 'ceremony') ...[
                      GlassTextField(
                        label: 'Subtitle',
                        controller: _subtitle,
                        hint: 'Opening Ceremony',
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_type == 'breakBand') ...[
                      const Text(
                        'Break icon',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.04,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: _breakIcons.map((o) {
                          final selected = _breakIcon == o.emoji;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _TypeChip(
                              label: o.label,
                              icon: o.icon,
                              selected: selected,
                              onTap: () => setState(() => _breakIcon = o.emoji),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (_type == 'sessionBlock') ...[
                      Row(
                        children: [
                          const Text(
                            'Talks',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textWhite,
                            ),
                          ),
                          const Spacer(),
                          GlassButton(
                            label: 'Add Talk',
                            icon: Icons.add,
                            onPressed: () => setState(() {
                              _talkKeys.add(GlobalKey<_TalkEditorState>());
                              _talkInitials.add(null);
                            }),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._talkKeys.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Talk ${entry.key + 1}',
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.06,
                                        color: AppColors.accent,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (_talkKeys.length > 1)
                                      GhostIconButton(
                                        icon: Icons.remove_circle_outline,
                                        color: AppColors.liveRedLight,
                                        onPressed: () => setState(() {
                                          _talkKeys.removeAt(entry.key);
                                          _talkInitials.removeAt(entry.key);
                                        }),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                _TalkEditor(
                                  key: _talkKeys[entry.key],
                                  initial: _talkInitials[entry.key],
                                  baseDate: _dayDate,
                                  lockedHall: AgendaDay.fromKey(
                                    widget.dayKey,
                                  ).hall,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    label: 'Save Session',
                    icon: Icons.save_outlined,
                    onPressed: _save,
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
                const Icon(
                  Icons.edit_calendar_outlined,
                  size: 14,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TalkEditor extends StatefulWidget {
  final Talk? initial;
  final DateTime baseDate;
  final String? lockedHall;
  const _TalkEditor({
    super.key,
    this.initial,
    required this.baseDate,
    this.lockedHall,
  });

  @override
  State<_TalkEditor> createState() => _TalkEditorState();
}

class _TalkEditorState extends State<_TalkEditor> {
  late final TextEditingController _title;
  late final TextEditingController _role;
  late final TextEditingController _hall;
  late final TextEditingController _sponsoredBy;
  late List<String> _speakers;
  late DateTime _startTime;
  late DateTime _endTime;
  late String _status;
  late String _type;

  static const _typeOptions = [
    (value: 'talk', label: 'Talk', icon: Icons.record_voice_over_outlined),
    (value: 'break', label: 'Break', icon: Icons.free_breakfast_outlined),
    (value: 'ceremony', label: 'Ceremony', icon: Icons.emoji_events_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _role = TextEditingController(text: initial?.role ?? '');
    _hall = TextEditingController(
      text: widget.lockedHall ?? initial?.hall ?? 'A',
    );
    _sponsoredBy = TextEditingController(text: initial?.sponsoredBy ?? '');
    _speakers = List<String>.from(initial?.speakers ?? const []);
    _startTime = initial?.startTime ?? DateTime(2026, 1, 1, 9, 0);
    _endTime = initial?.endTime ?? DateTime(2026, 1, 1, 9, 30);
    _status = initial?.status ?? 'upcoming';
    _type = initial?.type ?? 'talk';
  }

  @override
  void dispose() {
    _title.dispose();
    _role.dispose();
    _hall.dispose();
    _sponsoredBy.dispose();
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
      final value = DateTime(2026, 1, 1, time.hour, time.minute);
      if (isStart) {
        _startTime = value;
      } else {
        _endTime = value;
      }
    });
  }

  Talk? toTalk() {
    final title = _title.text.trim();
    if (title.isEmpty) return null;
    final base = widget.baseDate;
    return Talk(
      id: widget.initial?.id ?? Ids.generate(),
      type: _type,
      startTime: DateTime(
        base.year,
        base.month,
        base.day,
        _startTime.hour,
        _startTime.minute,
      ),
      endTime: DateTime(
        base.year,
        base.month,
        base.day,
        _endTime.hour,
        _endTime.minute,
      ),
      title: title,
      speakers: List<String>.from(_speakers),
      role: _role.text.trim(),
      hall: _hall.text.trim(),
      status: _status,
      sponsoredBy: _sponsoredBy.text.trim().isEmpty
          ? null
          : _sponsoredBy.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(width: 10),
            Expanded(
              child: _TimeField(
                label: 'End time',
                value: _endTime,
                onTap: () => _pickTime(isStart: false),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 140,
              child: GlassTextField(
                label: 'Title',
                controller: _title,
                hint: 'Talk title',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Type',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: _typeOptions.map((o) {
            final selected = _type == o.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _TypeChip(
                label: o.label,
                icon: o.icon,
                selected: selected,
                onTap: () => setState(() => _type = o.value),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _SpeakerField(
                label: 'Speakers',
                selected: _speakers,
                onChanged: (v) => setState(() => _speakers = v),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 120,
              child: widget.lockedHall != null
                  ? GlassTextField(
                      label: 'Hall',
                      controller: _hall,
                      hint: 'A',
                      enabled: false,
                    )
                  : GlassTextField(
                      label: 'Hall',
                      controller: _hall,
                      hint: 'A',
                    ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GlassTextField(label: 'Role', controller: _role, hint: 'Consultant'),
        const SizedBox(height: 10),
        GlassTextField(
          label: 'Sponsored by (optional)',
          controller: _sponsoredBy,
          hint: 'Company name',
        ),
      ],
    );
  }
}

/// Selectable pill used to choose a talk's type (talk / break / ceremony).
class _TypeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.glassBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.highlight : AppColors.glassBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppColors.highlight : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.highlight : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Searchable multi-select field for assigning speakers to a talk. Shows the
/// current selection as removable chips; tapping opens a search dialog backed
/// by the admin panel's user list.
class _SpeakerField extends StatelessWidget {
  final String label;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const _SpeakerField({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _open(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder: (_) => _SpeakerSearchDialog(selected: selected),
    );
    if (result != null) onChanged(result);
  }

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
          onTap: () => _open(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: selected.isEmpty
                ? const Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 16,
                        color: AppColors.textTertiary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Select speakers',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    ],
                  )
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ...selected.map((name) {
                        return Chip(
                          label: Text(
                            name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textWhite,
                            ),
                          ),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          onDeleted: () =>
                              onChanged(List.from(selected)..remove(name)),
                          backgroundColor: AppColors.primary,
                          side: const BorderSide(
                            color: AppColors.glassBorder,
                            width: 1,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }),
                      ActionChip(
                        avatar: const Icon(
                          Icons.add,
                          size: 14,
                          color: AppColors.accent,
                        ),
                        label: const Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                        onPressed: () => _open(context),
                        backgroundColor: AppColors.glassBg,
                        side: const BorderSide(color: AppColors.accent),
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Modal search dialog that lets the admin pick speakers from the panel's
/// user list. Users with professional roles (speaker/faculty/sponsor) are
/// offered with a role tag so faculty are clearly selectable as speakers, and
/// any already-selected names not in the list are kept available so legacy
/// talks stay editable. A free-text field below the search box lets the admin
/// add names with no matching user (faculty not yet provisioned, generic
/// labels like 'Course faculty', or simply more speakers once every listed
/// user is already selected).
class _SpeakerSearchDialog extends StatefulWidget {
  final List<String> selected;
  const _SpeakerSearchDialog({required this.selected});

  @override
  State<_SpeakerSearchDialog> createState() => _SpeakerSearchDialogState();
}

class _SpeakerSearchDialogState extends State<_SpeakerSearchDialog> {
  late final List<String> _selected;
  final TextEditingController _search = TextEditingController();
  final TextEditingController _customName = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
  }

  @override
  void dispose() {
    _search.dispose();
    _customName.dispose();
    super.dispose();
  }

  /// Adds a name typed in by the admin even when it has no matching user —
  /// e.g. a faculty member who isn't provisioned yet, or a generic name like
  /// 'Course faculty'. This lets talks keep accumulating speakers past the end
  /// of the registered-user list.
  void _addCustomName() {
    final name = _customName.text.trim();
    if (name.isEmpty) return;
    setState(() {
      if (!_selected.contains(name)) {
        _selected.add(name);
      }
      _customName.clear();
    });
  }

  /// Every user with a professional role — speaker, **faculty** and sponsor —
  /// is offered as a speaker option so talks can be assigned to faculty too.
  Future<List<PanelUser>> _loadUsers() async {
    final result = await sl<UsersRepository>().getUsers();
    return result.fold(
      (_) => const <PanelUser>[],
      (users) => users
          .where((u) => u.isProfessional && u.displayName.trim().isNotEmpty)
          .toList(),
    );
  }

  void _toggle(String name) {
    setState(() {
      if (_selected.contains(name)) {
        _selected.remove(name);
      } else {
        _selected.add(name);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 540),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  const Text(
                    'Select speakers',
                    style: TextStyle(fontFamily: 'Inter', fontSize: 16),
                  ),
                  const Spacer(),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _search,
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.textWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 18,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.glassBg,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customName,
                      onSubmitted: (_) => _addCustomName(),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a speaker not in the list…',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textDisabled,
                        ),
                        prefixIcon: const Icon(
                          Icons.person_add_alt_1,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.glassBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addCustomName,
                    tooltip: 'Add speaker',
                    icon: const Icon(
                      Icons.add_circle_outline,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<PanelUser>>(
                future: _loadUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  final roles = <String, String>{};
                  for (final u in snapshot.data ?? const <PanelUser>[]) {
                    roles[u.displayName.trim()] = u.role;
                  }
                  final options = <String>{...roles.keys};
                  options.addAll(_selected);
                  final list = options.toList()..sort();
                  final filtered = _query.isEmpty
                      ? list
                      : list
                            .where((n) => n.toLowerCase().contains(_query))
                            .toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No speakers found',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textDisabled,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final name = filtered[index];
                      final checked = _selected.contains(name);
                      final role = roles[name];
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (_) => _toggle(name),
                        dense: true,
                        activeColor: AppColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  color: AppColors.textWhite,
                                ),
                              ),
                            ),
                            if (role != null) ...[
                              const SizedBox(width: 8),
                              _RoleTag(role: role),
                            ],
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    '${_selected.length} selected',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  GlassButton(
                    label: 'Done',
                    icon: Icons.check,
                    onPressed: () => Navigator.pop(context, _selected),
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

/// Small role label shown next to a speaker option in the picker so the admin
/// can see at a glance whether an assignee is a speaker, faculty or sponsor.
class _RoleTag extends StatelessWidget {
  final String role;
  const _RoleTag({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'faculty' => ('Faculty', AppColors.pointsGreen),
      'sponsor' => ('Sponsor', AppColors.gold),
      _ => ('Speaker', AppColors.accent),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.04,
          color: color,
        ),
      ),
    );
  }
}
