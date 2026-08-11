import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_day.dart';
import 'package:afric_eg_admin_panel/features/agenda/domain/entities/agenda_item.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:equatable/equatable.dart';

class CongressState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final CongressConfig? config;
  final List<(AgendaDay, AgendaItem)> sessionBlocks;
  final String? error;

  const CongressState({
    this.isLoading = false,
    this.isSaving = false,
    this.config,
    this.sessionBlocks = const [],
    this.error,
  });

  CongressState copyWith({
    bool? isLoading,
    bool? isSaving,
    CongressConfig? config,
    List<(AgendaDay, AgendaItem)>? sessionBlocks,
    String? error,
  }) =>
      CongressState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        config: config ?? this.config,
        sessionBlocks: sessionBlocks ?? this.sessionBlocks,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props =>
      [isLoading, isSaving, config, sessionBlocks, error];
}
