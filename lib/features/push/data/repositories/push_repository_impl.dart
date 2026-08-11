import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/push/domain/entities/push_send_result.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

class PushRepositoryImpl implements PushRepository {
  final FirebaseFunctions _functions;

  PushRepositoryImpl({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  @override
  FutureResult<PushSendResult> sendToAll({
    required String title,
    required String message,
  }) =>
      _send({'title': title, 'message': message});

  @override
  FutureResult<PushSendResult> sendToUser({
    required String uid,
    required String title,
    required String message,
  }) =>
      _send({'uid': uid, 'title': title, 'message': message});

  FutureResult<PushSendResult> _send(Map<String, dynamic> data) async {
    try {
      final response = await _functions.httpsCallable('sendPush').call(data);
      final map = (response.data as Map).cast<String, dynamic>();
      return Right(PushSendResult.fromJson(map));
    } catch (e) {
      return Left(ServerFailure(message: _describe(e)));
    }
  }

  String _describe(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.isNotEmpty == true
          ? error.message
          : error.code.replaceAll('-', ' ');
      return message ?? 'Request failed';
    }
    return error.toString();
  }
}
