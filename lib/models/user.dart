class BaasProfile {
  final List<String> services;
  final double dailyRate;
  final String about;
  final String displayName;
  final String location;
  final bool active;
  final double platformFeeOwed;

  BaasProfile({
    required this.services,
    required this.dailyRate,
    required this.about,
    required this.displayName,
    required this.location,
    required this.active,
    required this.platformFeeOwed,
  });

  factory BaasProfile.fromJson(Map<String, dynamic> json) {
    return BaasProfile(
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
      dailyRate: (json['dailyRate'] as num?)?.toDouble() ?? 0,
      about: json['about'] as String? ?? '',
      displayName: json['displayName'] as String? ?? '',
      location: json['location'] as String? ?? '',
      active: json['active'] == true,
      platformFeeOwed: (json['platformFeeOwed'] as num?)?.toDouble() ?? 0,
    );
  }
}

class Verification {
  final String status; // "Pending" | "Approved" | "Rejected" | not submitted -> null
  final String? nic;
  final String? note;

  Verification({required this.status, this.nic, this.note});

  factory Verification.fromJson(Map<String, dynamic> json) {
    return Verification(
      status: json['status'] as String? ?? 'Pending',
      nic: json['nic'] as String?,
      note: json['note'] as String?,
    );
  }
}

class MybaasUser {
  final String id;
  final String mobile;
  final String email;
  final String firstName;
  final String middleName;
  final String lastName;
  final String profilePhoto;
  final String role; // "customer" | "baas" | "admin"
  final bool isAdmin;
  final Verification? verification;
  final BaasProfile? baasProfile;

  MybaasUser({
    required this.id,
    required this.mobile,
    required this.email,
    required this.firstName,
    required this.middleName,
    required this.lastName,
    required this.profilePhoto,
    required this.role,
    required this.isAdmin,
    this.verification,
    this.baasProfile,
  });

  String get fullName => [firstName, middleName, lastName]
      .where((s) => s.isNotEmpty)
      .join(' ');

  bool get isVerified => verification?.status == 'Approved';
  bool get isBaas => role == 'baas';

  factory MybaasUser.fromJson(Map<String, dynamic> json) {
    return MybaasUser(
      id: json['id'] as String? ?? '',
      mobile: json['mobile'] as String? ?? '',
      email: json['email'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      middleName: json['middleName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      role: json['role'] as String? ?? 'customer',
      isAdmin: json['isAdmin'] == true,
      verification: json['verification'] != null
          ? Verification.fromJson(json['verification'] as Map<String, dynamic>)
          : null,
      baasProfile: json['baasProfile'] != null
          ? BaasProfile.fromJson(json['baasProfile'] as Map<String, dynamic>)
          : null,
    );
  }
}
