class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    this.displayName,
    this.preferences = const {},
  });

  final int id;
  final String email;
  final String? displayName;
  final Map<String, dynamic> preferences;

  String get greetingName =>
      displayName?.trim().isNotEmpty == true ? displayName!.trim() : email;

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        id: json['id'] as int,
        email: json['email'] as String,
        displayName: json['display_name'] as String?,
        preferences: (json['preferences'] as Map<String, dynamic>?) ?? const {},
      );
}

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.expiresAt,
  });

  final AuthUser user;
  final String accessToken;
  final DateTime expiresAt;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
        accessToken: json['access_token'] as String,
        expiresAt: DateTime.parse(json['expires_at'] as String),
      );
}
