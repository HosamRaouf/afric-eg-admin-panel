import 'package:afric_eg_admin_panel/core/error/failures.dart';
import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';

/// Backed by the admin Cloud Functions (listUsers/createUser/updateUser/
/// deleteUser/sendVerificationCode). Only these can reach the Firebase Auth
/// Admin SDK, so they are the single source of truth for the users table.
abstract class UsersRepository {
  FutureResult<List<PanelUser>> getUsers();

  FutureResult<VerificationCodeResult> createUser({
    required String email,
    required String displayName,
    required String role,
    String title,
    String photoUrl,
    String password,
    bool manualPassword,
  });

  FutureResult<VerificationCodeResult> sendVerificationCode(String uid);

  FutureResult<PanelUser> updateUser({
    required String uid,
    String? email,
    String? displayName,
    String? title,
    String? photoUrl,
    String? role,
    String? password,
  });

  FutureResult<void> deleteUser(String uid);
}
