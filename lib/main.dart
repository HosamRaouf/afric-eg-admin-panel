import 'dart:async';
import 'dart:developer' as dev;
import 'dart:ui';

import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/firebase/firebase_options.dart';
import 'package:afric_eg_admin_panel/core/router/app_router.dart';
import 'package:afric_eg_admin_panel/core/theme/app_theme.dart';
import 'package:afric_eg_admin_panel/features/auth/domain/repositories/auth_repository.dart';
import 'package:afric_eg_admin_panel/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

void main() {
  // Use runZonedGuarded to fix Zone mismatch by keeping initialization and runApp in the same zone.
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // 1. Setup early error handling for the framework
      FlutterError.onError = (details) {
        dev.log(
          'FLUTTER ERROR: ${details.exception}',
          name: 'FlutterError',
          error: details.exception,
          stackTrace: details.stack,
        );
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
      };

      // 2. Setup platform/async error handling
      PlatformDispatcher.instance.onError = (error, stack) {
        dev.log(
          'UNCAUGHT ASYNC ERROR: $error',
          name: 'PlatformError',
          error: error,
          stackTrace: stack,
        );
        return true;
      };

      try {
        // 3. Initialize Core Services
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        await initDependencies();

        final authRepository = sl<AuthRepository>();
        final router = AppRouter(authRepository).router;

        runApp(
          BlocProvider<AuthBloc>(
            create: (_) => AuthBloc(repository: authRepository),
            child: AfricAdminApp(router: router),
          ),
        );
      } catch (e, stack) {
        dev.log('FATAL INIT ERROR: $e', error: e, stackTrace: stack);
        _runErrorApp(e.toString());
      }
    },
    (error, stack) {
      dev.log('ZONE ERROR: $error', error: error, stackTrace: stack);
      _runErrorApp(error.toString());
    },
  );
}

/// Fallback app to show errors and prevent EngineFlutterView disposal assertions on Web
void _runErrorApp(String message) {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: SelectableText(
              'Afric 2026 Admin Panel\nStartup Failure:\n$message',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 14),
            ),
          ),
        ),
      ),
    ),
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
