import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/congress/domain/entities/congress_config.dart';

abstract class CongressRepository {
  FutureResult<CongressConfig?> getConfig();
  FutureResult<void> updateConfig(CongressConfig config);
}
