import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:equatable/equatable.dart';

class CongressState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final CongressConfig? config;
  final String? error;

  const CongressState({
    this.isLoading = false,
    this.isSaving = false,
    this.config,
    this.error,
  });

  CongressState copyWith({
    bool? isLoading,
    bool? isSaving,
    CongressConfig? config,
    String? error,
  }) => CongressState(
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    config: config ?? this.config,
    error: error ?? this.error,
  );

  @override
  List<Object?> get props => [isLoading, isSaving, config, error];
}
