class UserModel {
  final String id;
  final String email;
  final String displayName;
  final String role;
  final String? avatarUrl;
  final UserSubscriptionInfo? subscription;

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    this.avatarUrl,
    this.subscription,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      role: json['role'] ?? 'USER',
      avatarUrl: json['avatarUrl'],
      subscription: json['subscription'] != null
          ? UserSubscriptionInfo.fromJson(json['subscription'])
          : null,
    );
  }
}

class UserSubscriptionInfo {
  final String planId;
  final String planName;
  final String status;
  final String? expiresAt;
  final String maxResolution;
  final int maxStreams;

  UserSubscriptionInfo({
    required this.planId,
    required this.planName,
    required this.status,
    this.expiresAt,
    this.maxResolution = '1080p',
    this.maxStreams = 1,
  });

  factory UserSubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionInfo(
      planId: json['planId'] ?? 'PLAN_FREE',
      planName: json['planName'] ?? 'Miễn Phí',
      status: json['status'] ?? 'ACTIVE',
      expiresAt: json['expiresAt'],
      maxResolution: json['maxResolution'] ?? '1080p',
      maxStreams: json['maxStreams'] ?? 1,
    );
  }
}
