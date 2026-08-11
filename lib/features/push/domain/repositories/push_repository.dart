import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/push/domain/entities/push_send_result.dart';

/// Backed by the `sendPush` Cloud Function, which delivers FCM notifications
/// to every registered device (or a single user when [sendToUser] is used).
abstract class PushRepository {
  FutureResult<PushSendResult> sendToAll({
    required String title,
    required String message,
  });

  FutureResult<PushSendResult> sendToUser({
    required String uid,
    required String title,
    required String message,
  });
}
