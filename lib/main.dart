import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/firebase/firebase_options.dart';
import 'package:afric_eg_admin_panel/core/router/app_router.dart';
import 'package:afric_eg_admin_panel/core/theme/app_theme.dart';
import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initDependencies();

  final router = AppRouter(sl<AuthRepository>()).router;

  runApp(
    BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(repository: sl<AuthRepository>()),
      child: AfricAdminApp(router: router),
    ),
  );
}

class AfricAdminApp extends StatelessWidget {
  final GoRouter router;

  const AfricAdminApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AFRIC Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
