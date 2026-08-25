enum AppointmentStatus {
  scheduled('scheduled'),
  completed('completed'),
  cancelled('cancelled');

  final String value;
  const AppointmentStatus(this.value);

  static AppointmentStatus fromString(String value) {
    return AppointmentStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AppointmentStatus.scheduled,
    );
  }
}

class Appointment {
  final String id;
  final String userId;
  final String title;
  final DateTime scheduledDateTime;
  final String? notes;
  final AppointmentStatus status;
  final String? completedEventId;

  const Appointment({
    required this.id,
    required this.userId,
    required this.title,
    required this.scheduledDateTime,
    this.notes,
    this.status = AppointmentStatus.scheduled,
    this.completedEventId,
  });

  bool get isScheduled => status == AppointmentStatus.scheduled;
  bool get isCompleted => status == AppointmentStatus.completed;
  bool get isCancelled => status == AppointmentStatus.cancelled;

  /// Returns whether the appointment time has arrived or passed, enabling completion.
  bool get canBeCompleted =>
      isScheduled &&
      (scheduledDateTime.isBefore(DateTime.now()) ||
          scheduledDateTime.isAtSameMomentAs(DateTime.now()));

  Appointment copyWith({
    String? id,
    String? userId,
    String? title,
    DateTime? scheduledDateTime,
    String? notes,
    AppointmentStatus? status,
    String? completedEventId,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      completedEventId: completedEventId ?? this.completedEventId,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'title': title,
    'scheduledDateTime': scheduledDateTime.toIso8601String(),
    'notes': notes,
    'status': status.value,
    'completedEventId': completedEventId,
  };

  factory Appointment.fromJson(Map<String, dynamic> json) => Appointment(
    id: json['id'] as String,
    userId: json['userId'] as String,
    title: json['title'] as String,
    scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
    notes: json['notes'] as String?,
    status: AppointmentStatus.fromString(json['status'] as String),
    completedEventId: json['completedEventId'] as String?,
  );

  Map<String, dynamic> toDbMap() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'scheduled_datetime': scheduledDateTime.toIso8601String(),
    'notes': notes,
    'status': status.value,
    'completed_event_id': completedEventId,
  };

  factory Appointment.fromDbMap(Map<String, dynamic> map) => Appointment(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    title: map['title'] as String,
    scheduledDateTime: DateTime.parse(map['scheduled_datetime'] as String),
    notes: map['notes'] as String?,
    status: AppointmentStatus.fromString(map['status'] as String),
    completedEventId: map['completed_event_id'] as String?,
  );
}
