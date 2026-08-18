import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';

abstract class SponsorRepository {
  FutureResult<List<Sponsor>> getSponsors();
  FutureResult<void> add(Sponsor sponsor);
  FutureResult<void> update(Sponsor sponsor);
  FutureResult<void> delete(String id);
}
