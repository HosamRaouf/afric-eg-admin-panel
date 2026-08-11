import 'package:afric_eg_admin_panel/features/overview/domain/entities/overview_data.dart';
import 'package:equatable/equatable.dart';

class OverviewState extends Equatable {
  final bool isLoading;
  final OverviewData? data;
  final String? error;

  const OverviewState({this.isLoading = false, this.data, this.error});

  OverviewState copyWith({bool? isLoading, OverviewData? data, String? error}) =>
      OverviewState(
        isLoading: isLoading ?? this.isLoading,
        data: data ?? this.data,
        error: error ?? this.error,
      );

  @override
  List<Object?> get props => [isLoading, data, error];
}
