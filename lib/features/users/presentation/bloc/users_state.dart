import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:equatable/equatable.dart';

class UsersState extends Equatable {
  final bool isLoading;
  final bool isSaving;
  final List<PanelUser> users;
  final String? error;
  final VerificationCodeResult? verificationCode;

  /// 'create' when a brand-new user was provisioned, 'send' when a code was
  /// re-issued for an existing user — drives the share dialog title.
  final String? codeAction;

  const UsersState({
    this.isLoading = false,
    this.isSaving = false,
    this.users = const [],
    this.error,
    this.verificationCode,
    this.codeAction,
  });

  UsersState copyWith({
    bool? isLoading,
    bool? isSaving,
    List<PanelUser>? users,
    String? error,
    VerificationCodeResult? verificationCode,
    String? codeAction,
  }) =>
      UsersState(
        isLoading: isLoading ?? this.isLoading,
        isSaving: isSaving ?? this.isSaving,
        users: users ?? this.users,
        error: error ?? this.error,
        verificationCode: verificationCode ?? this.verificationCode,
        codeAction: codeAction ?? this.codeAction,
      );

  @override
  List<Object?> get props => [isLoading, isSaving, users, error, verificationCode, codeAction];
}
