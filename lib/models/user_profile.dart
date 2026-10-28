class UserProfile {
  final String uid;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String accountStatus;
  final bool emailVerified;
  final String? pairedDeviceId;
  final Map<String, dynamic>? emergencyProfile;
  final String? createdAt;

  const UserProfile({
    required this.uid,
    required this.fullName,
    required this.email,
    this.phone,
    this.role = 'normal_user',
    this.accountStatus = 'active',
    this.emailVerified = false,
    this.pairedDeviceId,
    this.emergencyProfile,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      uid: json['uid'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'AEGIS User',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: json['role'] as String? ?? 'normal_user',
      accountStatus: json['account_status'] as String? ?? 'active',
      emailVerified: json['email_verified'] as bool? ?? false,
      pairedDeviceId: json['paired_device_id'] as String?,
      emergencyProfile: json['emergency_profile'] is Map<String, dynamic>
          ? json['emergency_profile'] as Map<String, dynamic>
          : null,
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'account_status': accountStatus,
      'email_verified': emailVerified,
      'paired_device_id': pairedDeviceId,
      'emergency_profile': emergencyProfile,
      'created_at': createdAt,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? phone,
    String? pairedDeviceId,
    Map<String, dynamic>? emergencyProfile,
  }) {
    return UserProfile(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      role: role,
      accountStatus: accountStatus,
      emailVerified: emailVerified,
      pairedDeviceId: pairedDeviceId ?? this.pairedDeviceId,
      emergencyProfile: emergencyProfile ?? this.emergencyProfile,
      createdAt: createdAt,
    );
  }
}
