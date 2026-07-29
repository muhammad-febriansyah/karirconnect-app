/// Mirrors `App\Http\Resources\Api\V1\UserResource`.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    required this.emailVerified,
    required this.onboardingCompleted,
    this.phone,
    this.avatarUrl,
    this.locale,
  });

  final int id;
  final String name;
  final String email;

  /// `employee`, `employer` or `admin`. This client only supports `employee`.
  final String role;

  final String? phone;
  final String? avatarUrl;
  final String? locale;
  final bool isActive;
  final bool emailVerified;
  final bool onboardingCompleted;

  bool get isEmployee => role == 'employee';

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num?)?.toInt() ?? 0,
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: json['role'] as String? ?? '',
        phone: json['phone'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        locale: json['locale'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        emailVerified: json['email_verified'] as bool? ?? false,
        onboardingCompleted: json['onboarding_completed'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role,
        'phone': phone,
        'avatar_url': avatarUrl,
        'locale': locale,
        'is_active': isActive,
        'email_verified': emailVerified,
        'onboarding_completed': onboardingCompleted,
      };
}

/// The `data.tokens` half of a login / register / refresh response.
class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    this.expiresIn,
    this.refreshExpiresAt,
  });

  final String accessToken;
  final String refreshToken;

  /// Access-token lifetime in seconds (`JWT_TTL` * 60 server-side).
  final int? expiresIn;
  final String? refreshExpiresAt;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String? ?? '',
        refreshToken: json['refresh_token'] as String? ?? '',
        expiresIn: (json['expires_in'] as num?)?.toInt(),
        refreshExpiresAt: json['refresh_expires_at'] as String?,
      );
}

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final UserModel user;
  final AuthTokens tokens;
}
