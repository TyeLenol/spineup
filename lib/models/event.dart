import 'dart:convert';

enum EventType {
  stretchCompleted('stretch_completed'),
  journalEntry('journal_entry'),
  appointmentAttended('appointment_attended'),
  angleLogged('angle_logged'),
  profileCompleted('profile_completed');

  final String value;
  const EventType(this.value);

  static EventType fromString(String value) {
    return EventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => throw ArgumentError('Unknown EventType value: $value'),
    );
  }
}

class Event {
  final String id;
  final String userId;
  final EventType type;
  final DateTime timestamp;
  final Map<String, dynamic> payload;
  final int xpValue;

  const Event({
    required this.id,
    required this.userId,
    required this.type,
    required this.timestamp,
    required this.payload,
    required this.xpValue,
  });

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'payload': jsonEncode(payload),
      'xp_value': xpValue,
    };
  }

  factory Event.fromDbMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      type: EventType.fromString(map['type'] as String),
      timestamp: DateTime.parse(map['timestamp'] as String),
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      xpValue: map['xp_value'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'type': type.value,
      'timestamp': timestamp.toIso8601String(),
      'payload': payload,
      'xpValue': xpValue,
    };
  }

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: EventType.fromString(json['type'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      xpValue: json['xpValue'] as int,
    );
  }

  Event copyWith({
    String? id,
    String? userId,
    EventType? type,
    DateTime? timestamp,
    Map<String, dynamic>? payload,
    int? xpValue,
  }) {
    return Event(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      payload: payload ?? this.payload,
      xpValue: xpValue ?? this.xpValue,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event &&
        other.id == id &&
        other.userId == userId &&
        other.type == type &&
        other.timestamp == timestamp &&
        other.xpValue == xpValue &&
        jsonEncode(other.payload) == jsonEncode(payload);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      userId,
      type,
      timestamp,
      jsonEncode(payload),
      xpValue,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, userId: $userId, type: ${type.value}, timestamp: ${timestamp.toIso8601String()}, xpValue: $xpValue, payload: $payload)';
  }
}
