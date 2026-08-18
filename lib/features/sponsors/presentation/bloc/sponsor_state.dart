import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';
import 'package:equatable/equatable.dart';

class SponsorState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<Sponsor> sponsors;
  final String? error;

  const SponsorState({
    this.isLoading = false,
    this.isSaving = false,
    this.sponsors = const [],
    this.error,
  });

  SponsorState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<Sponsor>? sponsors,
    String? error,
  }) =>
      SponsorState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        sponsors: sponsors ?? this.sponsors,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [isLoading, isSaving, sponsors, error];
}
