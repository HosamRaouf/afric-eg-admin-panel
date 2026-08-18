import 'dart:async';

import 'package:flutter/material.dart';

/// Shows a loading dialog, waits for a bloc stream transition, then shows a
/// success or error snackbar. Returns the final [S] state so callers can
/// inspect post-completion data (e.g. a verification code).
Future<S?> runActionWithFeedback<S>({
  required BuildContext context,
  required Stream<S> stream,
  required bool Function(S) isComplete,
  required String? Function(S) errorOf,
  required FutureOr<void> Function() dispatch,
  required String loadingMessage,
  required String successTitle,
  required String successMessage,
  required String errorTitle,
}) async {
  S? lastState;
  final completer = Completer<void>();

  late final StreamSubscription<S> sub;
  sub = stream.listen((s) {
    lastState = s;
    if (!completer.isCompleted && isComplete(s)) {
      completer.complete();
    }
  });

  await dispatch();

  if (!completer.isCompleted) {
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );
  }
  await sub.cancel();

  if (!context.mounted) return lastState;

  final S? finalState = lastState;
  final error = finalState != null ? errorOf(finalState) : null;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$errorTitle\n$error',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        ),
        backgroundColor: const Color(0xFF3a1515),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$successTitle — $successMessage',
          style: const TextStyle(fontFamily: 'Inter', fontSize: 12),
        ),
        backgroundColor: const Color(0xFF153a1a),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  return lastState;
}
