import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';
import 'package:equatable/equatable.dart';

abstract class CongressEvent extends Equatable {
  const CongressEvent();

  @override
  List<Object?> get props => [];
}

class LoadCongressEvent extends CongressEvent {
  const LoadCongressEvent();
}

class SaveCongressEvent extends CongressEvent {
  final CongressConfig config;
  const SaveCongressEvent(this.config);

  @override
  List<Object?> get props => [config];
}
