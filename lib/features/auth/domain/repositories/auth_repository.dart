import 'package:afric_eg_admin_panel/core/error/failures.dart';

abstract class AuthRepository {
  Stream<bool> get isSignedIn;
  FutureResult<void> signIn(String email, String password);
  FutureResult<void> signOut();
}
