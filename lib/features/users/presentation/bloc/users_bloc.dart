import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:afric_eg_admin_panel/features/users/domain/repositories/users_repository.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_event.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  final UsersRepository _repository;

  UsersBloc({required UsersRepository repository})
      : _repository = repository,
        super(const UsersState()) {
    on<LoadUsersEvent>(_onLoad);
    on<CreateUserEvent>(_onCreate);
    on<SendVerificationCodeEvent>(_onSendCode);
    on<UpdateUserEvent>(_onUpdate);
    on<DeleteUserEvent>(_onDelete);
    on<ClearVerificationCodeEvent>(
        (_, emit) => emit(state.copyWith(verificationCode: null, codeAction: null)));
  }

  Future<void> _onLoad(LoadUsersEvent event, Emitter<UsersState> emit) async {
    if (state.users.isNotEmpty) return;
    emit(state.copyWith(isLoading: true, isSaving: false, error: null));
    final result = await _repository.getUsers();
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(isLoading: false, error: failure.message)),
      (list) => emit(state.copyWith(isLoading: false, users: list)),
    );
  }

  Future<void> _onCreate(CreateUserEvent event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.createUser(
      email: event.email,
      displayName: event.displayName,
      role: event.role,
      title: event.title,
      photoUrl: event.photoUrl,
      password: event.password,
      manualPassword: event.manualPassword,
    );
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (code) {
        final users = [
          ...state.users,
          PanelUser(
            uid: code.uid,
            email: code.email,
            displayName: event.displayName,
            title: event.title,
            photoUrl: event.photoUrl,
            role: code.role,
            isFirstLogin: !event.manualPassword,
            firstLoginPassword: event.password,
          ),
        ];
        emit(state.copyWith(
          isSaving: false,
          users: users,
          verificationCode: code,
          codeAction: 'create',
        ));
      },
    );
  }

  Future<void> _onSendCode(
      SendVerificationCodeEvent event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.sendVerificationCode(event.uid);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (code) => emit(state.copyWith(
        isSaving: false,
        verificationCode: code,
        codeAction: 'send',
      )),
    );
  }

  Future<void> _onUpdate(UpdateUserEvent event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.updateUser(
      uid: event.uid,
      email: event.email,
      displayName: event.displayName,
      title: event.title,
      photoUrl: event.photoUrl,
      role: event.role,
      password: event.password,
    );
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (user) => emit(state.copyWith(
        isSaving: false,
        users: [
          for (final u in state.users)
            if (u.uid == event.uid) user else u,
        ],
      )),
    );
  }

  Future<void> _onDelete(DeleteUserEvent event, Emitter<UsersState> emit) async {
    emit(state.copyWith(isSaving: true, error: null));
    final result = await _repository.deleteUser(event.uid);
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(isSaving: false, error: failure.message)),
      (_) => emit(state.copyWith(
        isSaving: false,
        users: [
          for (final u in state.users)
            if (u.uid != event.uid) u,
        ],
      )),
    );
  }
}
