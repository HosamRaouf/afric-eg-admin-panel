import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/venue.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_bloc.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_event.dart';
import 'package:afric_eg_admin_panel/features/congress/presentation/bloc/congress_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CongressPage extends StatelessWidget {
  const CongressPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          CongressBloc(repository: sl())..add(const LoadCongressEvent()),
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
  DateTime _congressStart = DateTime.now();
  String _liveSessionId = '';
  final _venueNameController = TextEditingController();
  final _venueAddressController = TextEditingController();
  final _venueMapsUrlController = TextEditingController();
  bool _dirty = false;

  @override
  void dispose() {
    _venueNameController.dispose();
    _venueAddressController.dispose();
    _venueMapsUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CongressBloc, CongressState>(
      listener: (context, state) {
        final config = state.config;
        if (config != null && !_dirty) {
          _currentDay = config.currentDay;
          _congressStart = config.congressStart;
          _liveSessionId = config.liveSessionId;
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
                      'Controls what the app shows: current day, start time and the live session.',
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
                      Wrap(
                        spacing: 8,
                        children: List.generate(4, (i) {
                          final day = i + 1;
                          final active = day == _currentDay;
                          return InkWell(
                            onTap: () => setState(() {
                              _currentDay = day;
                              _dirty = true;
                            }),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: 44,
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
                              child: Center(
                                child: Text(
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
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 22),
                      InkWell(
                        onTap: _pickCongressStart,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.glassBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.event,
                                  size: 15, color: AppColors.accent),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Congress start: ${DateFormat.yMMMd().add_jm().format(_congressStart)}',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    color: AppColors.textWhite,
                                  ),
                                ),
                              ),
                              const Icon(Icons.edit_outlined,
                                  size: 14, color: AppColors.textTertiary),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Live Session',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _liveSessionId.isEmpty ? null : _liveSessionId,
                        dropdownColor: const Color(0xFF2a0f10),
                        isExpanded: true,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.textWhite,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: AppColors.glassBg,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.glassBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.accent),
                          ),
                        ),
                        hint: const Text(
                          'Select a session block',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        items: state.sessionBlocks
                            .map((entry) => DropdownMenuItem(
                                  value: entry.$2.id,
                                  child: Text(
                                    _blockLabel(entry.$1, entry.$2),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) => setState(() {
                          _liveSessionId = value ?? '';
                          _dirty = true;
                        }),
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
                          context.read<CongressBloc>().add(SaveCongressEvent(
                                CongressConfig(
                                  congressStart: _congressStart,
                                  currentDay: _currentDay,
                                  liveSessionId: _liveSessionId,
                                  venue: Venue(
                                    name: _venueNameController.text.trim(),
                                    address: _venueAddressController.text.trim(),
                                    mapsUrl:
                                        _venueMapsUrlController.text.trim(),
                                  ),
                                ),
                              ));
                          _dirty = false;
                        },
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

  String _blockLabel(AgendaDay day, AgendaItem item) {
    final jm = DateFormat.jm();
    return 'Day ${day.day} · ${item.title} '
        '(${jm.format(item.startTime)}–${jm.format(item.endTime)})';
  }

  Future<void> _pickCongressStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _congressStart,
      firstDate: DateTime(2026, 1, 1),
      lastDate: DateTime(2027, 12, 31),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_congressStart),
    );
    if (time == null) return;
    if (!mounted) return;
    setState(() {
      _congressStart = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _dirty = true;
    });
  }
}
