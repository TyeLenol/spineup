enum LearnReviewState { reviewed, sourceLinked, draft }

extension LearnReviewStateLabel on LearnReviewState {
  String get label {
    switch (this) {
      case LearnReviewState.reviewed:
        return 'Reviewed';
      case LearnReviewState.sourceLinked:
        return 'Source linked';
      case LearnReviewState.draft:
        return 'Draft';
    }
  }
}

class LearnSource {
  final String organization;
  final String title;
  final String url;
  final String? author;
  final String? license;

  const LearnSource({
    required this.organization,
    required this.title,
    required this.url,
    this.author,
    this.license,
  });
}

/// One canonical educational record reused by the Learn library and `?` help.
class LearnTopic {
  final String id;
  final String title;
  final String category;
  final String shortExplanation;
  final String body;
  final String audience;
  final String limitations;
  final String safetyNote;
  final LearnReviewState reviewState;
  final DateTime lastVerified;
  final List<LearnSource> sources;
  final List<String> relatedTopicIds;

  const LearnTopic({
    required this.id,
    required this.title,
    required this.category,
    required this.shortExplanation,
    required this.body,
    required this.audience,
    required this.limitations,
    required this.safetyNote,
    required this.reviewState,
    required this.lastVerified,
    required this.sources,
    this.relatedTopicIds = const [],
  });
}

const _srsBracingManual = LearnSource(
  organization: 'Scoliosis Research Society',
  title: 'SRS Bracing Manual',
  url:
      'https://www.srs.org/Education/Manuals-and-Presentations/SRS-Bracing-Manual',
  license: 'Public web reference; link to source',
);

const _nhsAdultScoliosis = LearnSource(
  organization: 'NHS',
  title: 'Treatment in adults — scoliosis',
  url: 'https://www.nhs.uk/conditions/scoliosis/treatment-in-adults/',
  license: 'Public web reference; link to source',
);

const _nhsYoungPeopleScoliosis = LearnSource(
  organization: 'NHS Inform / NHS 24',
  title: 'Scoliosis treatment for children and young people',
  url:
      'https://www.nhsinform.scot/illnesses-and-conditions/muscle-bone-and-joints/neck-and-back-problems-and-conditions/scoliosis/scoliosis-treatment-for-children-and-young-people/',
  license: 'Public web reference; link to source',
);

const _sosortGuidelines = LearnSource(
  organization: 'SOSORT',
  title: '2016 SOSORT guidelines',
  url: 'https://pmc.ncbi.nlm.nih.gov/articles/PMC5795289/',
  author: 'Negrini et al.',
  license: 'Open-access journal article; link to source',
);

const _spineUpProject = LearnSource(
  organization: 'SpineUp team',
  title: 'SpineUp project documentation',
  url: 'https://github.com/TyeLenol/spineup',
  license: 'Project documentation; link to source',
);

const spineUpLearnTopics = <LearnTopic>[
  LearnTopic(
    id: 'cobb-angle',
    title: 'Cobb angle',
    category: 'Measurements',
    shortExplanation:
        'A number from an imaging report that describes a spinal curve measurement.',
    body:
        'A Cobb angle is a measurement made from spinal imaging. If your clinician or report gives you a number, SpineUp can help you record it with its date and source. SpineUp does not read scans, calculate the angle, or decide what a change means.',
    audience:
        'People recording a measurement and caregivers helping them organize records.',
    limitations:
        'A recorded number is not a diagnosis, a prediction, or a conclusion about progression. Different images, methods, and reviewers can affect measurements.',
    safetyNote:
        'Use the number and wording from your clinical report when possible. Ask your clinician if you are unsure what a measurement means.',
    reviewState: LearnReviewState.sourceLinked,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [_sosortGuidelines],
    relatedTopicIds: ['measurement-log', 'brace-type'],
  ),
  LearnTopic(
    id: 'brace-type',
    title: 'Brace type',
    category: 'Braces',
    shortExplanation:
        'The name or broad category of the brace recorded for a profile.',
    body:
        'Brace names and designs can differ. Use the name supplied by the clinician, orthotist, or brace provider rather than guessing from appearance. SpineUp records the label you choose; it does not recommend a brace or calculate how long it should be worn.',
    audience:
        'People who use a brace and caregivers organizing brace information.',
    limitations:
        'A brace type alone cannot tell SpineUp whether it is appropriate, correctly fitted, or suitable for a particular person.',
    safetyNote:
        'For fit, wear schedule, skin concerns, pain, or changes in symptoms, contact the relevant healthcare professional or orthotist.',
    reviewState: LearnReviewState.sourceLinked,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [_srsBracingManual, _nhsYoungPeopleScoliosis],
    relatedTopicIds: ['exercise-safety', 'measurement-log'],
  ),
  LearnTopic(
    id: 'exercise-safety',
    title: 'Exercise safety',
    category: 'Movement',
    shortExplanation:
        'A reminder to use exercises that are appropriate for the person and their care plan.',
    body:
        'Exercise information can be useful, but one routine is not right for everyone. SpineUp can link to source-aware exercises and help you record what you tried. It does not prescribe a routine or replace assessment by a qualified professional.',
    audience:
        'People choosing educational movement content and caregivers supporting routines.',
    limitations:
        'General exercise information cannot account for a person’s diagnosis, surgery, pain, brace, age, or other health circumstances.',
    safetyNote:
        'Before starting a new programme, check that it is suitable with a healthcare professional. Stop an activity that causes pain or concerning symptoms and seek appropriate help.',
    reviewState: LearnReviewState.sourceLinked,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [
      _nhsAdultScoliosis,
      _nhsYoungPeopleScoliosis,
      _sosortGuidelines,
    ],
    relatedTopicIds: ['brace-type'],
  ),
  LearnTopic(
    id: 'measurement-log',
    title: 'Why record measurements?',
    category: 'Using SpineUp',
    shortExplanation:
        'Recording a date and source can help keep personal information organized for appointments.',
    body:
        'A measurement entry is a personal record. Adding the date, source, and a note can help you remember where the information came from and prepare questions for an appointment. SpineUp shows recorded information; it does not draw clinical conclusions from it.',
    audience:
        'All SpineUp users, including caregivers managing a separate subject profile.',
    limitations:
        'The app cannot verify a measurement, compare images, or determine whether a curve has changed clinically.',
    safetyNote:
        'Bring questions about measurements or changes to a qualified healthcare professional.',
    reviewState: LearnReviewState.draft,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [_spineUpProject],
    relatedTopicIds: ['cobb-angle', 'export-import'],
  ),
  LearnTopic(
    id: 'sex-assigned-at-birth',
    title: 'Why do we ask about sex assigned at birth?',
    category: 'Profile and privacy',
    shortExplanation:
        'This is an optional, sensitive profile field that you can skip.',
    body:
        'SpineUp asks this as an optional piece of profile context because some educational information may be discussed differently across populations. You can choose “Prefer not to say” or leave it unselected. The app does not use this field to diagnose, predict progression, or decide treatment.',
    audience:
        'People completing their own profile and caregivers supporting setup.',
    limitations:
        'This field is not a substitute for a clinical history, and the app does not infer identity or health status from it.',
    safetyNote:
        'Only enter information you are comfortable storing locally on the device.',
    reviewState: LearnReviewState.draft,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [_spineUpProject],
    relatedTopicIds: ['export-import'],
  ),
  LearnTopic(
    id: 'export-import',
    title: 'Export and import rights',
    category: 'Privacy and portability',
    shortExplanation:
        'Your local records should be portable, reviewable, and deletable by you.',
    body:
        'SpineUp is designed to keep health information on the device by default. The planned archive will be human-readable and protected, show a preview before import, and require explicit confirmation rather than silently merging data. This portability workflow is not yet available in the current prototype.',
    audience:
        'All users, especially caregivers managing more than one subject profile.',
    limitations:
        'Do not treat the current prototype as a completed backup system. Until export/import is implemented, use the app as local prototype storage only.',
    safetyNote:
        'Do not share health records or passphrases through an unsafe channel. Confirm the destination before transferring any future archive.',
    reviewState: LearnReviewState.draft,
    lastVerified: DateTime(2026, 8, 12),
    sources: const [_spineUpProject],
    relatedTopicIds: ['measurement-log', 'sex-assigned-at-birth'],
  ),
];

LearnTopic? learnTopicById(String id) {
  for (final topic in spineUpLearnTopics) {
    if (topic.id == id) return topic;
  }
  return null;
}
