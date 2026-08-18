import 'dart:async';
import 'dart:developer' as dev;

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

  // Capture the ORIGINAL error before Flutter's broken web error reporter
  // tries to render it and crashes with the _debugRender null check.
  FlutterError.onError = (details) {
    dev.log(
      'FLUTTER ERROR: ${details.exception}\n${details.stack}',
      name: 'FlutterError',
      error: details.exception,
      stackTrace: details.stack,
    );
    // Do NOT call FlutterError.presentError — it triggers the broken
    // _debugRender path on web. Just log to dev console.
  };

  ErrorWidget.builder = (details) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Text(
          'Error: ${details.exception}',
          style: const TextStyle(color: Colors.red, fontSize: 12),
        ),
      ),
    );
  };

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initDependencies();

  final router = AppRouter(sl<AuthRepository>()).router;

  runZonedGuarded(
    () {
      runApp(
        BlocProvider<AuthBloc>(
          create: (_) => AuthBloc(repository: sl<AuthRepository>()),
          child: AfricAdminApp(router: router),
        ),
      );
    },
    (error, stackTrace) {
      dev.log(
        'UNCAUGHT: $error',
        name: 'ZoneError',
        error: error,
        stackTrace: stackTrace,
      );
    },
  );
}

class AfricAdminApp extends StatelessWidget {
  final GoRouter router;

  const AfricAdminApp({super.key, required this.router});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Afric 2026 - Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
