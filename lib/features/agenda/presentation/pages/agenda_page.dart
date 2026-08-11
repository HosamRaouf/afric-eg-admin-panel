import 'package:afric_eg_admin_panel/core/data/datasources/admin_data_source.dart';
import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/agenda/data/repositories/speaker_talk_sync.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/talk.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_bloc.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_state.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AgendaPage extends StatelessWidget {
  const AgendaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AgendaBloc(
        repository: sl(),
        speakerTalkSync: SpeakerTalkSync(
          dataSource: sl<AdminDataSource>(),
          users: sl<UsersRepository>(),
        ),
      )..add(const LoadAgendaEvent()),
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
                trailing: GlassButton(
                  label: 'Add Session Block',
                  icon: Icons.add,
                  onPressed: state.selectedDayKey == null
                      ? null
                      : () => _openEditor(
                            context,
                            dayKey: state.selectedDayKey!,
                          ),
                ),
              ),
              const SizedBox(height: 18),
              if (state.days.isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: state.days.map((day) {
                    final active = day.key == state.selectedDayKey;
                    return InkWell(
                      onTap: () =>
                          context.read<AgendaBloc>().add(SelectDayEvent(day.key)),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.glassBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: active
                                ? AppColors.gold.withValues(alpha: 0.3)
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
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
                      .map((item) => _AgendaItemCard(
                            item: item,
                            onEdit: () => _openEditor(
                              context,
                              dayKey: state.selectedDayKey!,
                              item: item,
                            ),
                            onDelete: () => _confirmDelete(
                                context, state.selectedDayKey!, item),
                          ))
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
                        color: AppColors.liveRed),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEditor(BuildContext context,
      {required String dayKey, AgendaItem? item}) async {
    final config = await sl<AdminDataSource>().getConfig();
    if (!context.mounted) return;
    final bloc = context.read<AgendaBloc>();
    showDialog(
      context: context,
      builder: (_) => _AgendaItemDialog(
        dayKey: dayKey,
        item: item,
        congressStart: config?.congressStart ?? DateTime(2026, 9, 5),
        bloc: bloc,
      ),
    );
  }

  void _confirmDelete(BuildContext context, String dayKey, AgendaItem item) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Delete agenda item?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
        content: Text(
          item.title,
          style: const TextStyle(
              fontFamily: 'Inter', fontSize: 12, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<AgendaBloc>()
                  .add(DeleteAgendaItemEvent(dayKey, item.id));
              Navigator.pop(dialogContext);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.liveRed)),
          ),
        ],
      ),
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
  final DateTime congressStart;
  final AgendaBloc bloc;

  const _AgendaItemDialog({
    required this.dayKey,
    this.item,
    required this.congressStart,
    required this.bloc,
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
  late final List<GlobalKey<_TalkEditorState>> _talkKeys;
  late final List<Talk?> _talkInitials;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _title = TextEditingController(text: item?.title ?? '');
    _subtitle = TextEditingController(text: item?.subtitle ?? '');
    final start = widget.congressStart;
    final dayNum = AgendaDay.fromKey(widget.dayKey).day;
    _dayDate = DateTime(start.year, start.month, start.day + (dayNum - 1));
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
    final isNew = widget.item == null;
    final talks = _talkKeys
        .map((k) => k.currentState?.toTalk())
        .whereType<Talk>()
        .toList();
    final item = AgendaItem(
      type: 'sessionBlock',
      id: widget.item?.id ?? Ids.generate(),
      title: _title.text.trim(),
      startTime: _resolveToDay(_startTime),
      endTime: _resolveToDay(_endTime),
      talks: talks,
    );
    widget.bloc
        .add(SaveAgendaItemEvent(widget.dayKey, item, isNew: isNew));
    Navigator.pop(context);  }

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
                    style: const TextStyle(
                        fontFamily: 'Inter', fontSize: 16),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textTertiary),
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
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
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
                const Icon(Icons.schedule,
                    size: 16, color: AppColors.textTertiary),
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
                const Icon(Icons.edit_calendar_outlined,
                    size: 14, color: AppColors.textDisabled),
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
  const _TalkEditor({super.key, this.initial, required this.baseDate});

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

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _title = TextEditingController(text: initial?.title ?? '');
    _role = TextEditingController(text: initial?.role ?? '');
    _hall = TextEditingController(text: initial?.hall ?? 'A');
    _sponsoredBy = TextEditingController(text: initial?.sponsoredBy ?? '');
    _speakers = List<String>.from(initial?.speakers ?? const []);
    _startTime = initial?.startTime ?? DateTime(2026, 1, 1, 9, 0);
    _endTime = initial?.endTime ?? DateTime(2026, 1, 1, 9, 30);
    _status = initial?.status ?? 'upcoming';
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
      startTime:
          DateTime(base.year, base.month, base.day, _startTime.hour, _startTime.minute),
      endTime:
          DateTime(base.year, base.month, base.day, _endTime.hour, _endTime.minute),
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
              child: GlassTextField(
                label: 'Hall',
                controller: _hall,
                hint: 'A',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: GlassTextField(
                label: 'Role',
                controller: _role,
                hint: 'Consultant',
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 140,
              child: DropdownButtonFormField<String>(
                initialValue: _status,
                dropdownColor: const Color(0xFF2a0f10),
                isExpanded: true,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textWhite,
                ),
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.glassBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.glassBorder),
                  ),
                ),
                items: ['upcoming', 'live', 'completed']
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(s,
                              style: const TextStyle(fontSize: 11)),
                        ))
                    .toList(),
                onChanged: (v) => _status = v ?? 'upcoming',
              ),
            ),
          ],
        ),
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
                      Icon(Icons.person_outline,
                          size: 16, color: AppColors.textTertiary),
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
                    children: selected.map((name) {
                      return Chip(
                        label: Text(name,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textWhite,
                            )),
                        deleteIcon: const Icon(Icons.close,
                            size: 14, color: AppColors.textTertiary),
                        onDeleted: () =>
                            onChanged(List.from(selected)..remove(name)),
                        backgroundColor: AppColors.primary,
                        side: const BorderSide(
                            color: AppColors.glassBorder, width: 1),
                        visualDensity: VisualDensity.compact,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4),
                      );
                    }).toList(),
                  ),
          ),
        ),
      ],
    );
  }
}

/// Modal search dialog that lets the admin pick speakers from the panel's
/// user list. Users with professional roles (speaker/faculty/sponsor) are
/// offered first, and any already-selected names not in the list are kept
/// available so legacy talks stay editable.
class _SpeakerSearchDialog extends StatefulWidget {
  final List<String> selected;
  const _SpeakerSearchDialog({required this.selected});

  @override
  State<_SpeakerSearchDialog> createState() => _SpeakerSearchDialogState();
}

class _SpeakerSearchDialogState extends State<_SpeakerSearchDialog> {
  late final List<String> _selected;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selected);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<List<String>> _loadUsers() async {
    final result = await sl<UsersRepository>().getUsers();
    return result.fold(
      (_) => const <String>[],
      (users) => users
          .where((u) => u.isProfessional && u.displayName.trim().isNotEmpty)
          .map((u) => u.displayName.trim())
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
                  const Text('Select speakers',
                      style: TextStyle(fontFamily: 'Inter', fontSize: 16)),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close,
                        size: 18, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                style: const TextStyle(
                    fontFamily: 'Inter', fontSize: 13, color: AppColors.textWhite),
                decoration: InputDecoration(
                  hintText: 'Search by name…',
                  hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.textDisabled),
                  prefixIcon: const Icon(Icons.search,
                      size: 18, color: AppColors.textTertiary),
                  filled: true,
                  fillColor: AppColors.glassBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.glassBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<String>>(
                future: _loadUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  final options = <String>{...snapshot.data ?? const []};
                  options.addAll(_selected);
                  final list = options.toList()..sort();
                  final filtered = _query.isEmpty
                      ? list
                      : list.where((n) => n.toLowerCase().contains(_query)).toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No speakers found',
                          style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 12,
                              color: AppColors.textDisabled)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final name = filtered[index];
                      final checked = _selected.contains(name);
                      return CheckboxListTile(
                        value: checked,
                        onChanged: (_) => _toggle(name),
                        dense: true,
                        activeColor: AppColors.accent,
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(name,
                            style: const TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 13,
                                color: AppColors.textWhite)),
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
                        color: AppColors.textTertiary),
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
