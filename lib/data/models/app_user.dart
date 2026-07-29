import 'enums.dart';

/// users table/collection
class AppUser {
  final String id;
  final String phone; // full E.164, e.g. +919876543210
  final String countryCode; // e.g. +91
  final String name;
  final UserRole role;
  final LaborerType? laborerType; // only for UserRole.laborer
  final String? companyName; // exporter / investor entity
  final String? registrationNo; // exporter company registration
  final String? country; // for foreign investor / exporter
  final String district;
  final VerificationStatus verificationStatus;
  final int freeJobPostsUsed;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.phone,
    required this.countryCode,
    required this.name,
    required this.role,
    required this.district,
    required this.createdAt,
    this.laborerType,
    this.companyName,
    this.registrationNo,
    this.country,
    this.verificationStatus = VerificationStatus.approved,
    this.freeJobPostsUsed = 0,
  });

  bool get isApproved => verificationStatus == VerificationStatus.approved;
  bool get isPending => verificationStatus == VerificationStatus.pending;

  AppUser copyWith({
    String? name,
    UserRole? role,
    LaborerType? laborerType,
    String? companyName,
    String? registrationNo,
    String? country,
    String? district,
    VerificationStatus? verificationStatus,
    int? freeJobPostsUsed,
  }) {
    return AppUser(
      id: id,
      phone: phone,
      countryCode: countryCode,
      name: name ?? this.name,
      role: role ?? this.role,
      laborerType: laborerType ?? this.laborerType,
      companyName: companyName ?? this.companyName,
      registrationNo: registrationNo ?? this.registrationNo,
      country: country ?? this.country,
      district: district ?? this.district,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      freeJobPostsUsed: freeJobPostsUsed ?? this.freeJobPostsUsed,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'phone': phone,
    'country_code': countryCode,
    'name': name,
    'role': role.name,
    'laborer_type': laborerType?.name,
    'company_name': companyName,
    'registration_no': registrationNo,
    'country': country,
    'district': district,
    'verification_status': verificationStatus.name,
    'free_job_posts_used': freeJobPostsUsed,
    'created_at': createdAt.toIso8601String(),
  };

  factory AppUser.fromMap(Map<dynamic, dynamic> m) => AppUser(
    id: m['id'] as String? ?? '',
    phone: m['phone'] as String? ?? '',
    countryCode: m['country_code'] as String? ?? '+91',
    name: m['name'] as String? ?? 'User',
    role: UserRoleX.fromId(m['role'] as String? ?? 'buyer'),
    laborerType: m['laborer_type'] == null
        ? null
        : LaborerTypeX.fromId(m['laborer_type'] as String),
    companyName: m['company_name'] as String?,
    registrationNo: m['registration_no'] as String?,
    country: m['country'] as String?,
    district: m['district'] as String? ?? '',
    verificationStatus:
        VerificationStatusX.fromId(m['verification_status'] as String? ?? 'approved'),
    freeJobPostsUsed: (m['free_job_posts_used'] as num?)?.toInt() ?? 0,
    createdAt:
        DateTime.tryParse(m['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
