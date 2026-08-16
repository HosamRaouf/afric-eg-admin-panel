import 'package:equatable/equatable.dart';

/// Outcome of a push notification send (from the `sendPush` Cloud Function).
class PushSendResult extends Equatable {
  final int success;
  final int failure;
  final int total;
  final String? targeted;
  final bool topicSent;

  const PushSendResult({
    required this.success,
    required this.failure,
    required this.total,
    this.targeted,
    this.topicSent = false,
  });

  factory PushSendResult.fromJson(Map<String, dynamic> json) => PushSendResult(
        success: json['success'] as int? ?? 0,
        failure: json['failure'] as int? ?? 0,
        total: json['total'] as int? ?? 0,
        targeted: json['targeted'] as String?,
        topicSent: json['topicSent'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [success, failure, total, targeted, topicSent];
}
