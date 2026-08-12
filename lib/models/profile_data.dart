
enum TreatmentStage { observation, bracing, preOp, postOp, adult, unsure }
enum CurveType { thoracic, lumbar, thoracolumbar, doubleS, unsure }
enum BraceType { boston, rigoCheneau, providence, spinecor, other, none }
enum PtMethod { schroth, seas, otherPsse, none, unsure }
enum Sex { female, male, intersex, preferNot, none }
enum UnitSystem { metric, imperial }
enum Goal { reducePain, braceHours, ptConsistency, prepSurgery, trackProgression, exploring }

class ProfileConsent {
  final bool onDevice;
  final bool analytics;
  final DateTime? acceptedAt;

  const ProfileConsent({
    this.onDevice = true,
    this.analytics = false,
    this.acceptedAt,
  });

  Map<String, dynamic> toJson() => {
        'onDevice': onDevice,
        'analytics': analytics,
        'acceptedAt': acceptedAt?.toIso8601String(),
      };

  factory ProfileConsent.fromJson(Map<String, dynamic> json) => ProfileConsent(
        onDevice: json['onDevice'] ?? true,
        analytics: json['analytics'] ?? false,
        acceptedAt: json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt']) : null,
      );
}

class ProfileBasics {
  final String displayName;
  final String dob;
  final Sex sex;

  const ProfileBasics({
    this.displayName = '',
    this.dob = '',
    this.sex = Sex.none,
  });

  Map<String, dynamic> toJson() => {
        'displayName': displayName,
        'dob': dob,
        'sex': sex.name,
      };

  factory ProfileBasics.fromJson(Map<String, dynamic> json) => ProfileBasics(
        displayName: json['displayName'] ?? '',
        dob: json['dob'] ?? '',
        sex: Sex.values.firstWhere((e) => e.name == json['sex'], orElse: () => Sex.none),
      );
}

class ProfileBody {
  final UnitSystem units;
  final double? heightCm;
  final double? weightKg;

  const ProfileBody({
    this.units = UnitSystem.metric,
    this.heightCm,
    this.weightKg,
  });

  Map<String, dynamic> toJson() => {
        'units': units.name,
        'heightCm': heightCm,
        'weightKg': weightKg,
      };

  factory ProfileBody.fromJson(Map<String, dynamic> json) => ProfileBody(
        units: UnitSystem.values.firstWhere((e) => e.name == json['units'], orElse: () => UnitSystem.metric),
        heightCm: json['heightCm']?.toDouble(),
        weightKg: json['weightKg']?.toDouble(),
      );
}

class ProfileStory {
  final String? diagnosisDate;
  final TreatmentStage? treatmentStage;

  const ProfileStory({this.diagnosisDate, this.treatmentStage});

  ProfileStory copyWith({
    String? diagnosisDate,
    TreatmentStage? treatmentStage,
  }) {
    return ProfileStory(
      diagnosisDate: diagnosisDate ?? this.diagnosisDate,
      treatmentStage: treatmentStage ?? this.treatmentStage,
    );
  }

  Map<String, dynamic> toJson() => {
        'diagnosisDate': diagnosisDate,
        'treatmentStage': treatmentStage?.name,
      };

  factory ProfileStory.fromJson(Map<String, dynamic> json) => ProfileStory(
        diagnosisDate: json['diagnosisDate'],
        treatmentStage: json['treatmentStage'] != null
            ? TreatmentStage.values.firstWhere((e) => e.name == json['treatmentStage'], orElse: () => TreatmentStage.unsure)
            : null,
      );
}

class ProfileCurve {
  final double? cobbPrimary;
  final double? cobbSecondary;
  final CurveType? curveType;
  final int? risser;
  final String? lenke;

  const ProfileCurve({
    this.cobbPrimary,
    this.cobbSecondary,
    this.curveType,
    this.risser,
    this.lenke,
  });

  Map<String, dynamic> toJson() => {
        'cobbPrimary': cobbPrimary,
        'cobbSecondary': cobbSecondary,
        'curveType': curveType?.name,
        'risser': risser,
        'lenke': lenke,
      };

  factory ProfileCurve.fromJson(Map<String, dynamic> json) => ProfileCurve(
        cobbPrimary: json['cobbPrimary']?.toDouble(),
        cobbSecondary: json['cobbSecondary']?.toDouble(),
        curveType: json['curveType'] != null
            ? CurveType.values.firstWhere((e) => e.name == json['curveType'], orElse: () => CurveType.unsure)
            : null,
        risser: json['risser']?.toInt(),
        lenke: json['lenke'],
      );
}

class ProfileBrace {
  final bool? wears;
  final BraceType? type;
  final double? hoursPerDay;
  final String? startDate;

  const ProfileBrace({this.wears, this.type, this.hoursPerDay, this.startDate});

  Map<String, dynamic> toJson() => {
        'wears': wears,
        'type': type?.name,
        'hoursPerDay': hoursPerDay,
        'startDate': startDate,
      };

  factory ProfileBrace.fromJson(Map<String, dynamic> json) => ProfileBrace(
        wears: json['wears'],
        type: json['type'] != null
            ? BraceType.values.firstWhere((e) => e.name == json['type'], orElse: () => BraceType.other)
            : null,
        hoursPerDay: json['hoursPerDay']?.toDouble(),
        startDate: json['startDate'],
      );
}

class ProfilePt {
  final PtMethod? method;

  const ProfilePt({this.method});

  Map<String, dynamic> toJson() => {'method': method?.name};

  factory ProfilePt.fromJson(Map<String, dynamic> json) => ProfilePt(
        method: json['method'] != null
            ? PtMethod.values.firstWhere((e) => e.name == json['method'], orElse: () => PtMethod.unsure)
            : null,
      );
}

class ProfileSymptoms {
  final int? pain;
  final int? fatigue;
  final String? activity;

  const ProfileSymptoms({this.pain, this.fatigue, this.activity});

  Map<String, dynamic> toJson() => {
        'pain': pain,
        'fatigue': fatigue,
        'activity': activity,
      };

  factory ProfileSymptoms.fromJson(Map<String, dynamic> json) => ProfileSymptoms(
        pain: json['pain']?.toInt(),
        fatigue: json['fatigue']?.toInt(),
        activity: json['activity'],
      );
}

class ProfileCompanion {
  final String name;
  final String color; // sage, coral, lavender

  const ProfileCompanion({this.name = 'Vera', this.color = 'sage'});

  Map<String, dynamic> toJson() => {'name': name, 'color': color};

  factory ProfileCompanion.fromJson(Map<String, dynamic> json) => ProfileCompanion(
        name: json['name'] ?? 'Vera',
        color: json['color'] ?? 'sage',
      );
}

class ProfileData {
  final ProfileConsent consent;
  final ProfileBasics basics;
  final ProfileBody body;
  final ProfileStory story;
  final ProfileCurve curve;
  final ProfileBrace brace;
  final ProfilePt pt;
  final ProfileSymptoms symptoms;
  final List<Goal> goals;
  final ProfileCompanion companion;
  final DateTime? completedAt;
  final int xp;

  const ProfileData({
    this.consent = const ProfileConsent(),
    this.basics = const ProfileBasics(),
    this.body = const ProfileBody(),
    this.story = const ProfileStory(),
    this.curve = const ProfileCurve(),
    this.brace = const ProfileBrace(),
    this.pt = const ProfilePt(),
    this.symptoms = const ProfileSymptoms(),
    this.goals = const [],
    this.companion = const ProfileCompanion(),
    this.completedAt,
    this.xp = 0,
  });

  ProfileData copyWith({
    ProfileConsent? consent,
    ProfileBasics? basics,
    ProfileBody? body,
    ProfileStory? story,
    ProfileCurve? curve,
    ProfileBrace? brace,
    ProfilePt? pt,
    ProfileSymptoms? symptoms,
    List<Goal>? goals,
    ProfileCompanion? companion,
    DateTime? completedAt,
    int? xp,
  }) {
    return ProfileData(
      consent: consent ?? this.consent,
      basics: basics ?? this.basics,
      body: body ?? this.body,
      story: story ?? this.story,
      curve: curve ?? this.curve,
      brace: brace ?? this.brace,
      pt: pt ?? this.pt,
      symptoms: symptoms ?? this.symptoms,
      goals: goals ?? this.goals,
      companion: companion ?? this.companion,
      completedAt: completedAt ?? this.completedAt,
      xp: xp ?? this.xp,
    );
  }

  Map<String, dynamic> toJson() => {
        'consent': consent.toJson(),
        'basics': basics.toJson(),
        'body': body.toJson(),
        'story': story.toJson(),
        'curve': curve.toJson(),
        'brace': brace.toJson(),
        'pt': pt.toJson(),
        'symptoms': symptoms.toJson(),
        'goals': goals.map((e) => e.name).toList(),
        'companion': companion.toJson(),
        'completedAt': completedAt?.toIso8601String(),
        'xp': xp,
      };

  factory ProfileData.fromJson(Map<String, dynamic> json) => ProfileData(
        consent: json['consent'] != null ? ProfileConsent.fromJson(json['consent']) : const ProfileConsent(),
        basics: json['basics'] != null ? ProfileBasics.fromJson(json['basics']) : const ProfileBasics(),
        body: json['body'] != null ? ProfileBody.fromJson(json['body']) : const ProfileBody(),
        story: json['story'] != null ? ProfileStory.fromJson(json['story']) : const ProfileStory(),
        curve: json['curve'] != null ? ProfileCurve.fromJson(json['curve']) : const ProfileCurve(),
        brace: json['brace'] != null ? ProfileBrace.fromJson(json['brace']) : const ProfileBrace(),
        pt: json['pt'] != null ? ProfilePt.fromJson(json['pt']) : const ProfilePt(),
        symptoms: json['symptoms'] != null ? ProfileSymptoms.fromJson(json['symptoms']) : const ProfileSymptoms(),
        goals: (json['goals'] as List<dynamic>?)?.map((e) => Goal.values.firstWhere((g) => g.name == e, orElse: () => Goal.exploring)).toList() ?? [],
        companion: json['companion'] != null ? ProfileCompanion.fromJson(json['companion']) : const ProfileCompanion(),
        completedAt: json['completedAt'] != null ? DateTime.tryParse(json['completedAt']) : null,
        xp: json['xp'] ?? 0,
      );
}
