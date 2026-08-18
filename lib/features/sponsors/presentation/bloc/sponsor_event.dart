import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';
import 'package:equatable/equatable.dart';

abstract class SponsorEvent extends Equatable {
  const SponsorEvent();

  @override
  List<Object?> get props => [];
}

class LoadSponsorsEvent extends SponsorEvent {
  const LoadSponsorsEvent();
}

class SaveSponsorEvent extends SponsorEvent {
  final Sponsor sponsor;
  final bool isNew;
  const SaveSponsorEvent(this.sponsor, {this.isNew = false});

  @override
  List<Object?> get props => [sponsor, isNew];
}

class DeleteSponsorEvent extends SponsorEvent {
  final String id;
  const DeleteSponsorEvent(this.id);

  @override
  List<Object?> get props => [id];
}
