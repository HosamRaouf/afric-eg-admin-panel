/// A user of the AFRIC 2026 ecosystem, as returned by the admin
/// `listUsers`/`updateUser`/`createUser` Cloud Functions.
///
/// `role` is one of `attendee | speaker | faculty | sponsor | admin`; `title`
/// is the professional/job title (e.g. 'Professor of OB/GYN') used by the
/// professional roles.
class PanelUser {
  final String uid;
  final String email;
  final String displayName;
  final String title;
  final String photoUrl;
  final String role;
  final bool isFirstLogin;
  final bool disabled;
  final String createdAt;

  const PanelUser({
    required this.uid,
    required this.email,
    this.displayName = '',
    this.title = '',
    this.photoUrl = '',
    this.role = 'attendee',
    this.isFirstLogin = false,
    this.disabled = false,
    this.createdAt = '',
  });

  factory PanelUser.fromJson(Map<String, dynamic> json) {
    return PanelUser(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      title: json['title'] as String? ?? '',
      photoUrl: json['photoURL'] as String? ?? '',
      role: json['role'] as String? ?? 'attendee',
      isFirstLogin: json['isFirstLogin'] as bool? ?? false,
      disabled: json['disabled'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  PanelUser copyWith({
    String? displayName,
    String? title,
    String? email,
    String? photoUrl,
    String? role,
    bool? isFirstLogin,
  }) {
    return PanelUser(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      title: title ?? this.title,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      disabled: disabled,
      createdAt: createdAt,
    );
  }

  static const professionalRoles = ['speaker', 'faculty', 'sponsor'];

  bool get isProfessional => professionalRoles.contains(role);

  bool get isAdmin => role == 'admin';

  String get initials {
    final name = displayName.trim();
    if (name.isNotEmpty) {
      final parts = name.split(RegExp(r'\s+'));
      var result = parts.first[0];
      if (parts.length > 1 && parts.last.isNotEmpty) {
        result += parts.last[0];
      }
      return result.toUpperCase();
    }
    if (email.isNotEmpty) return email[0].toUpperCase();
    return '?';
  }
}

/// Result of issuing (or creating with) a verification code — includes the
/// code itself, the QR payload (`email:code`) and whether the email was sent.
class VerificationCodeResult {
  final String uid;
  final String email;
  final String code;
  final String qrPayload;
  final String role;
  final bool emailed;
  final String emailError;

  const VerificationCodeResult({
    required this.uid,
    required this.email,
    required this.code,
    required this.qrPayload,
    required this.role,
    required this.emailed,
    this.emailError = '',
  });

  factory VerificationCodeResult.fromJson(Map<String, dynamic> json) {
    return VerificationCodeResult(
      uid: json['uid'] as String? ?? '',
      email: json['email'] as String? ?? '',
      code: json['code'] as String? ?? '',
      qrPayload: json['qrPayload'] as String? ?? '',
      role: json['role'] as String? ?? 'attendee',
      emailed: json['emailed'] as bool? ?? false,
      emailError: json['emailError'] as String? ?? '',
    );
  }
}
