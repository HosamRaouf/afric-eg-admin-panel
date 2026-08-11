import 'dart:async';

import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_event.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _repository;
  StreamSubscription<bool>? _subscription;

  AuthBloc({required AuthRepository repository})
      : _repository = repository,
        super(const AuthState()) {
    on<AuthStateChanged>(_onAuthStateChanged);
    on<SignInRequested>(_onSignInRequested);
    on<SignOutRequested>(_onSignOutRequested);

    _subscription = _repository.isSignedIn.listen((signedIn) {
      if (!isClosed) add(AuthStateChanged(signedIn));
    });
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }

  void _onAuthStateChanged(AuthStateChanged event, Emitter<AuthState> emit) {
    emit(state.copyWith(
      status: event.signedIn
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
    ));
  }

  Future<void> _onSignInRequested(
      SignInRequested event, Emitter<AuthState> emit) async {
    emit(state.copyWith(isLoading: true, error: null));
    final result = await _repository.signIn(event.email, event.password);
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        isLoading: false,
        error: failure.message,
      )),
      (_) => emit(state.copyWith(
        isLoading: false,
        status: AuthStatus.authenticated,
      )),
    );
  }

  Future<void> _onSignOutRequested(
      SignOutRequested event, Emitter<AuthState> emit) async {
    await _repository.signOut();
    emit(state.copyWith(
      status: AuthStatus.unauthenticated,
      error: null,
    ));
  }
}
