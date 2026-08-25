import 'profile_data.dart';

/// The person whose health-related information is recorded in SpineUp.
///
/// A session owner may have one self subject or multiple ward subjects. The
/// structured [profileData] remains stored through [ProfileStore] because it is
/// richer than the SQLite subject index; it is included here so callers can
/// treat a care subject and its onboarding context as one domain object.
class CareSubject {
  final String id;
  final String ownerUserId;
  final CareSubjectType type;
  final String displayName;
  final String? relationship;
  final ProfileData profileData;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CareSubject({
    required this.id,
    required this.ownerUserId,
    required this.type,
    required this.displayName,
    this.relationship,
    this.profileData = const ProfileData(),
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isSelf => type == CareSubjectType.self;
  bool get isWard => type == CareSubjectType.ward;

  CareSubject copyWith({
    String? id,
    String? ownerUserId,
    CareSubjectType? type,
    String? displayName,
    String? relationship,
    ProfileData? profileData,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CareSubject(
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      type: type ?? this.type,
      displayName: displayName ?? this.displayName,
      relationship: relationship ?? this.relationship,
      profileData: profileData ?? this.profileData,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'owner_user_id': ownerUserId,
    'subject_type': type.name,
    'display_name': displayName,
    'relationship': relationship,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory CareSubject.fromDbMap(
    Map<String, dynamic> map, {
    ProfileData profileData = const ProfileData(),
  }) {
    return CareSubject(
      id: map['id'] as String,
      ownerUserId: map['owner_user_id'] as String,
      type: CareSubjectType.values.firstWhere(
        (value) => value.name == map['subject_type'],
        orElse: () => CareSubjectType.self,
      ),
      displayName: map['display_name'] as String? ?? '',
      relationship: map['relationship'] as String?,
      profileData: profileData,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
