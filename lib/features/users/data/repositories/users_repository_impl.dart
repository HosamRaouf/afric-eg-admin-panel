import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dartz/dartz.dart';

class UsersRepositoryImpl implements UsersRepository {
  final FirebaseFunctions _functions;

  UsersRepositoryImpl({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instanceFor(region: 'us-central1');

  Future<Map<String, dynamic>> _call(
      String name, Map<String, dynamic> data) async {
    final response = await _functions.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(
        (response.data as Map).cast<String, dynamic>());
  }

  @override
  FutureResult<List<PanelUser>> getUsers() async {
    try {
      final data = await _call('listUsers', {});
      final rawUsers = (data['users'] as List? ?? const [])
          .map((e) => PanelUser.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
      return Right(rawUsers);
    } catch (e) {
      return Left(ServerFailure(message: _describe(e)));
    }
  }

  @override
  FutureResult<VerificationCodeResult> createUser({
    required String email,
    required String displayName,
    required String role,
    String title = '',
    String photoUrl = '',
  }) async {
    try {
      final data = await _call('createUser', {
        'email': email.trim().toLowerCase(),
        'displayName': displayName.trim(),
        'role': role,
        if (title.trim().isNotEmpty) 'title': title.trim(),
        if (photoUrl.trim().isNotEmpty) 'photoURL': photoUrl.trim(),
      });
      return Right(VerificationCodeResult.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: _describe(e)));
    }
  }

  @override
  FutureResult<VerificationCodeResult> sendVerificationCode(String uid) async {
    try {
      final data = await _call('sendVerificationCode', {'uid': uid});
      return Right(VerificationCodeResult.fromJson(data));
    } catch (e) {
      return Left(ServerFailure(message: _describe(e)));
    }
  }

  @override
  FutureResult<PanelUser> updateUser({
    required String uid,
    String? email,
    String? displayName,
    String? title,
    String? photoUrl,
    String? role,
  }) async {
    try {
      final data = await _call('updateUser', {
        'uid': uid,
        'email': ?(email?.trim().toLowerCase()),
        'displayName': ?(displayName?.trim()),
        'title': ?(title?.trim()),
        'photoURL': ?(photoUrl?.trim()),
        'role': ?role,
      });
      return Right(PanelUser.fromJson({...data, 'uid': uid}));
    } catch (e) {
      return Left(ServerFailure(message: _describe(e)));
    }
  }

  @override
  FutureResult<void> deleteUser(String uid) async {
    try {
      await _call('deleteUser', {'uid': uid});
      return const Right(null);
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
