// Web-only admin panel: native drag & drop requires dart:html.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_bloc.dart';
import 'package:afric_eg_admin_panel/features/agenda/presentation/bloc/agenda_event.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/venue.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_bloc.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_event.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_state.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CongressPage extends StatelessWidget {
  const CongressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<CongressBloc>(),
      child: const _CongressView(),
    );
  }
}

class _CongressView extends StatefulWidget {
  const _CongressView();

  @override
  State<_CongressView> createState() => _CongressViewState();
}

class _CongressViewState extends State<_CongressView> {
  int _currentDay = 1;
  List<DateTime> _eventDates = [];
  String _programGlanceUrl = '';
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _venueMapsUrlController = TextEditingController();
  bool _dirty = false;

  /// Set when the user saves the config; cleared once the save succeeds and
  /// the agenda bloc has been told to re-fetch its day list (the congress
  /// config is the source of truth for which days exist).
  bool _pendingAgendaSync = false;

  @override
  void initState() {
    super.initState();
    // Re-mounting the page must not blank the Event Days list: the congress
    // bloc is a lazy singleton whose state is already loaded on re-navigation,
    // so no new state is emitted for the BlocConsumer listener to react to.
    // Seed the local form state from the bloc's current config instead.
    _syncFromConfig(context.read<CongressBloc>().state.config);
  }

  @override
  void dispose() {
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _venueMapsUrlController.dispose();
    super.dispose();
  }

  void _syncFromConfig(CongressConfig? config) {
    if (config == null) return;
    _eventDates = List<DateTime>.from(config.eventDates);
    _currentDay = config.eventDates.isEmpty
        ? 1
        : config.currentDay > config.eventDates.length
        ? config.eventDates.length
        : config.currentDay;
    _programGlanceUrl = config.programGlanceUrl;
    _venueNameController.text = config.venue.name.isEmpty
        ? 'InterContinental Citystars Cairo'
        : config.venue.name;
    _venueAddressController.text = config.venue.address.isEmpty
        ? 'Citystars, Omar Ibn El-Khattab St, Nasr City, Cairo'
        : config.venue.address;
    _venueMapsUrlController.text = config.venue.mapsUrl.isEmpty
        ? 'https://maps.app.goo.gl/nEADtLq1cYs9CHdE8'
        : config.venue.mapsUrl;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CongressBloc, CongressState>(
      listener: (context, state) {
        final config = state.config;
        if (config != null && !_dirty) {
          _syncFromConfig(config);
        }
        if (_pendingAgendaSync && !state.isSaving && state.error == null) {
          _pendingAgendaSync = false;
          sl<AgendaBloc>().add(const LoadAgendaEvent(force: true));
        }
      },
      builder: (context, state) {
        if (state.isLoading && state.config == null) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (state.error != null && state.config == null) {
          return EmptyState(message: state.error!);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const PageHeader(
                  title: 'Congress Config',
                  subtitle:
                      'Controls what the app shows: current day and the event dates.',
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Current Day',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_eventDates.isEmpty)
                        const Text(
                          'No event days configured yet. Add one below.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        )
                      else
                        Wrap(
                          spacing: 8,
                          children: List.generate(_eventDates.length, (i) {
                            final day = i + 1;
                            final active = day == _currentDay;
                            return InkWell(
                              onTap: () => setState(() {
                                _currentDay = day;
                                _dirty = true;
                              }),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
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
                                child: Column(
                                  children: [
                                    Text(
                                      'Day $day',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: active
                                            ? AppColors.textWhite
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat.MMMd().format(_eventDates[i]),
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9,
                                        color: active
                                            ? AppColors.textWhite
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      const SizedBox(height: 22),
                      const Text(
                        'Event Days',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Each congress day maps to a real calendar date shown in '
                        'the app instead of static “Day 1 / Day 2”. Saving '
                        'creates the matching day track in the Agenda (day N · '
                        'Hall A) and removing a day deletes its agenda tracks.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_eventDates.isEmpty)
                        const Text(
                          'No days yet.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                        )
                      else
                        ..._eventDates.asMap().entries.map((entry) {
                          final day = entry.key + 1;
                          final date = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: () => _editEventDate(entry.key),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.glassBg,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.event,
                                      size: 15,
                                      color: AppColors.accent,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Day $day — '
                                        '${DateFormat.yMMMd().add_jm().format(date)}',
                                        style: const TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          color: AppColors.textWhite,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _removeEventDate(entry.key),
                                      icon: const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: AppColors.textTertiary,
                                      ),
                                      tooltip: 'Remove day',
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      const SizedBox(height: 6),
                      GlassButton(
                        label: 'Add Day',
                        icon: Icons.calendar_month_outlined,
                        onPressed: _addEventDate,
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Venue',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassTextField(
                        label: 'Venue name',
                        hint: 'InterContinental Citystars Cairo',
                        controller: _venueNameController,
                        onChanged: (_) => setState(() => _dirty = true),
                      ),
                      const SizedBox(height: 14),
                      GlassTextField(
                        label: 'Address',
                        hint: 'Citystars, Nasr City, Cairo',
                        controller: _venueAddressController,
                        maxLines: 2,
                        onChanged: (_) => setState(() => _dirty = true),
                      ),
                      const SizedBox(height: 14),
                      GlassTextField(
                        label: 'Maps / directions link',
                        hint: 'https://maps.app.goo.gl/…',
                        controller: _venueMapsUrlController,
                        keyboardType: TextInputType.url,
                        onChanged: (_) => setState(() => _dirty = true),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Shown in the app home hero; “Get Directions” opens this link.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          state.error!,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            color: AppColors.liveRed,
                          ),
                        ),
                      ],
                      const SizedBox(height: 22),
                      GlassButton(
                        label: state.isSaving ? 'Saving…' : 'Save Config',
                        icon: Icons.save_outlined,
                        loading: state.isSaving,
                        onPressed: () {
                          _pendingAgendaSync = true;
                          context.read<CongressBloc>().add(
                            SaveCongressEvent(
                              CongressConfig(
                                eventDates: _eventDates,
                                currentDay: _currentDay,
                                venue: Venue(
                                  name: _venueNameController.text.trim(),
                                  address: _venueAddressController.text.trim(),
                                  mapsUrl: _venueMapsUrlController.text.trim(),
                                ),
                                programGlanceUrl: _programGlanceUrl,
                              ),
                            ),
                          );
                          _dirty = false;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Program at a Glance',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textWhite,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Upload the full-program PDF. The app home screen '
                        'shows a widget that opens this file when tapped. '
                        'Save Config writes the link to the database.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _ProgramGlanceUpload(
                        value: _programGlanceUrl,
                        onChanged: (url) => setState(() {
                          _programGlanceUrl = url;
                          _dirty = true;
                        }),
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

  Future<void> _addEventDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _eventDates = List<DateTime>.from(
        _eventDates,
      )..add(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      _dirty = true;
    });
  }

  Future<void> _editEventDate(int index) async {
    final current = _eventDates[index];
    final date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      final updated = List<DateTime>.from(_eventDates)
        ..[index] = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      _eventDates = updated;
      _dirty = true;
    });
  }

  void _removeEventDate(int index) {
    setState(() {
      _eventDates = List<DateTime>.from(_eventDates)..removeAt(index);
      if (_currentDay > _eventDates.length && _eventDates.isNotEmpty) {
        _currentDay = _eventDates.length;
      } else if (_eventDates.isEmpty) {
        _currentDay = 1;
      }
      _dirty = true;
    });
  }
}

/// Drag & drop / browse PDF upload for the "Program at a Glance" file.
///
/// Uploads to `config/program_at_glance.pdf` in Storage and reports the
/// download URL back through [onChanged]. Keeps the last stored URL in
/// [value] so the admin can see what is currently published.
class _ProgramGlanceUpload extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _ProgramGlanceUpload({required this.value, required this.onChanged});

  @override
  State<_ProgramGlanceUpload> createState() => _ProgramGlanceUploadState();
}

class _ProgramGlanceUploadState extends State<_ProgramGlanceUpload> {
  bool _dragging = false;
  bool _uploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final win = html.window;
    win.addEventListener('dragover', _onDragOver);
    win.addEventListener('dragleave', _onDragLeave);
    win.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    final win = html.window;
    win.removeEventListener('dragover', _onDragOver);
    win.removeEventListener('dragleave', _onDragLeave);
    win.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  void _onDragOver(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (!_dragging) setState(() => _dragging = true);
  }

  void _onDragLeave(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    if (_dragging) setState(() => _dragging = false);
  }

  void _onDrop(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (_dragging) setState(() => _dragging = false);
    final data = (e as dynamic).dataTransfer as html.DataTransfer?;
    final dropped = data?.files;
    final file = (dropped == null || dropped.isEmpty) ? null : dropped.first;
    if (file != null) _readAndUpload(file);
  }

  void _browse() {
    final input = html.FileUploadInputElement()
      ..accept = 'application/pdf,.pdf'
      ..multiple = false;
    void cleanup() => input.remove();
    input.onChange.first.then((_) {
      cleanup();
      final files = input.files;
      final file = (files == null || files.isEmpty) ? null : files.first;
      if (file != null) _readAndUpload(file);
    }, onError: (_) => cleanup());
    input.on['cancel'].first.then((_) => cleanup());
    html.document.body?.append(input);
    input.click();
  }

  void _readAndUpload(html.File file) {
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final bytes = reader.result;
      if (bytes is Uint8List) _upload(bytes);
    });
    reader.readAsArrayBuffer(file);
  }

  Future<void> _upload(Uint8List bytes) async {
    setState(() {
      _uploading = true;
      _error = null;
    });
    try {
      final ref = FirebaseStorage.instance.ref('config/program_at_glance.pdf');
      await ref.putData(
        bytes,
        SettableMetadata(
          contentType: 'application/pdf',
          cacheControl: 'public,max-age=86400',
        ),
      );
      final url = await ref.getDownloadURL();
      if (!mounted) return;
      widget.onChanged(url);
      setState(() => _uploading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _error = 'Upload failed. Try again or check your connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.value.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasFile) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.picture_as_pdf,
                  size: 16,
                  color: AppColors.liveRed,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Program PDF uploaded — shown on the app home screen.',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _uploading ? null : () => widget.onChanged(''),
                  icon: const Icon(
                    Icons.close,
                    size: 16,
                    color: AppColors.textTertiary,
                  ),
                  tooltip: 'Remove program PDF',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
        InkWell(
          onTap: _uploading ? null : _browse,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: _dragging
                  ? AppColors.accent.withValues(alpha: 0.12)
                  : AppColors.glassBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _dragging ? AppColors.accent : AppColors.glassBorder,
              ),
            ),
            child: _uploading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.upload_file,
                        size: 16,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasFile
                            ? 'Replace PDF — drop a file or click to browse'
                            : 'Drop the program PDF here or click to browse',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              color: AppColors.liveRed,
            ),
          ),
        ],
      ],
    );
  }
}
