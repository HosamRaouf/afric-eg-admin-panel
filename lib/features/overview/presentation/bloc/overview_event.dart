import 'package:equatable/equatable.dart';

abstract class OverviewEvent extends Equatable {
  const OverviewEvent();

  @override
  List<Object?> get props => [];
}

class LoadOverviewEvent extends OverviewEvent {
  /// When `true` the load runs even if data is already present — used by the
  /// page's manual Refresh button.
  final bool force;
  const LoadOverviewEvent({this.force = false});

  @override
  List<Object?> get props => [force];
}
