import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cryptography_plus/cryptography_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/appointment.dart';
import '../models/care_subject.dart';
import '../models/event.dart';
import '../models/profile_data.dart';
import 'profile_store.dart';

class PortableArchiveException implements Exception {
  final String message;

  const PortableArchiveException(this.message);

  @override
  String toString() => message;
}

enum ArchiveImportMode { separateSubjects, replaceSelectedSubject }

class ArchiveSubjectPreview {
  final String displayName;
  final CareSubjectType type;
  final String? relationship;
  final int eventCount;
  final int appointmentCount;
  final bool hasProfile;

  const ArchiveSubjectPreview({
    required this.displayName,
    required this.type,
    required this.relationship,
    required this.eventCount,
    required this.appointmentCount,
    required this.hasProfile,
  });

  String get typeLabel =>
      type == CareSubjectType.self ? 'Me' : 'Someone I care for';
}

class ArchivePreview {
  final DateTime exportedAt;
  final int schemaVersion;
  final List<ArchiveSubjectPreview> subjects;
  final List<String> omittedAttachments;

  const ArchivePreview({
    required this.exportedAt,
    required this.schemaVersion,
    required this.subjects,
    required this.omittedAttachments,
  });

  int get eventCount => subjects.fold(0, (sum, item) => sum + item.eventCount);
  int get appointmentCount =>
      subjects.fold(0, (sum, item) => sum + item.appointmentCount);
}

class ArchiveImportResult {
  final List<String> importedSubjectIds;
  final int importedEventCount;
  final int importedAppointmentCount;

  const ArchiveImportResult({
    required this.importedSubjectIds,
    required this.importedEventCount,
    required this.importedAppointmentCount,
  });
}

/// Builds and restores protected, owner-scoped SpineUp archives.
///
/// The encrypted payload is UTF-8 JSON so that a correctly decrypted archive is
/// human-readable. The outer envelope contains only algorithm metadata and the
/// authenticated ciphertext; health data is not exposed without the passphrase.
class PortableArchiveService {
  static const String format = 'spineup.protected-archive';
  static const int schemaVersion = 1;
  static const String cipherName = 'AES-256-GCM';
  static const String kdfName = 'Argon2id';
  static const int _saltLength = 16;
  static const int _argonMemory = 32 * 1024;
  static const int _argonParallelism = 2;
  static const int _argonIterations = 2;
  static const int _argonHashLength = 32;

  final DatabaseHelper database;
  final Uuid _uuid;

  PortableArchiveService({DatabaseHelper? database, Uuid? uuid})
    : database = database ?? DatabaseHelper(),
      _uuid = uuid ?? const Uuid();

  Future<Uint8List> exportOwner({
    required String ownerUserId,
    required String passphrase,
  }) async {
    _validatePassphrase(passphrase);
    final payload = await _buildPayload(ownerUserId);
    final payloadBytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    final salt = _secureRandomBytes(_saltLength);
    final aad = _aadFor(salt: salt);
    final key = await _deriveKey(passphrase, salt);
    final secretBox = await AesGcm.with256bits().encrypt(
      payloadBytes,
      secretKey: key,
      aad: aad,
    );

    final envelope = <String, dynamic>{
      'format': format,
      'schemaVersion': schemaVersion,
      'cipher': cipherName,
      'kdf': kdfName,
      'kdfParameters': {
        'memory': _argonMemory,
        'parallelism': _argonParallelism,
        'iterations': _argonIterations,
        'hashLength': _argonHashLength,
      },
      'salt': base64UrlEncode(salt),
      'nonce': base64UrlEncode(secretBox.nonce),
      'mac': base64UrlEncode(secretBox.mac.bytes),
      'ciphertext': base64UrlEncode(secretBox.cipherText),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'payloadEncoding': 'utf-8-json',
    };
    return Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
  }

  Future<ArchivePreview> inspect({
    required Uint8List archiveBytes,
    required String passphrase,
  }) async {
    final payload = await _decryptPayload(archiveBytes, passphrase);
    return _previewFromPayload(payload);
  }

  Future<ArchiveImportResult> importArchive({
    required String ownerUserId,
    required Uint8List archiveBytes,
    required String passphrase,
    required ArchiveImportMode mode,
    String? replaceSubjectId,
  }) async {
    final payload = await _decryptPayload(archiveBytes, passphrase);
    final subjects = _subjectMaps(payload);
    if (subjects.isEmpty) {
      throw const PortableArchiveException(
        'This archive contains no profiles.',
      );
    }

    if (mode == ArchiveImportMode.replaceSelectedSubject) {
      if (subjects.length != 1 || replaceSubjectId == null) {
        throw const PortableArchiveException(
          'Replace mode requires exactly one archived profile and one selected local profile.',
        );
      }
      final selected = await database.getCareSubject(
        ownerUserId: ownerUserId,
        careSubjectId: replaceSubjectId,
      );
      if (selected == null) {
        throw const PortableArchiveException(
          'The selected local profile is no longer available.',
        );
      }
    } else {
      final localSubjects = await database.getCareSubjects(ownerUserId);
      final importsSelf = subjects.any(
        (subject) => _subjectType(subject) == CareSubjectType.self,
      );
      final hasLocalSelf = localSubjects.any((subject) => subject.isSelf);
      if (importsSelf && hasLocalSelf) {
        throw const PortableArchiveException(
          'This archive includes a “Me” profile, but this session already has one. Choose replace mode or remove the local self profile first; SpineUp will not silently convert or merge profiles.',
        );
      }
    }

    final importedSubjectIds = <String>[];
    var eventCount = 0;
    var appointmentCount = 0;
    for (var index = 0; index < subjects.length; index++) {
      final subject = subjects[index];
      final targetId = mode == ArchiveImportMode.replaceSelectedSubject
          ? replaceSubjectId!
          : _uuid.v4();
      final originalId = subject['originalId'] as String? ?? 'subject_$index';
      final sourceEvents = _eventMaps(subject);
      final sourceAppointments = _appointmentMaps(subject);
      final eventIdMap = <String, String>{
        for (final event in sourceEvents)
          if (event['id'] is String)
            event['id']
                as String: mode == ArchiveImportMode.replaceSelectedSubject
                ? event['id'] as String
                : _uuid.v4(),
      };

      if (mode == ArchiveImportMode.replaceSelectedSubject) {
        await database.clearCareSubjectRecords(
          ownerUserId: ownerUserId,
          careSubjectId: targetId,
        );
      }

      final existing = await database.getCareSubject(
        ownerUserId: ownerUserId,
        careSubjectId: targetId,
      );
      final now = DateTime.now();
      final importedType = _subjectType(subject);
      final importedProfile = ProfileData.fromJson(
        _map(subject['profileData']),
      );
      final importedSubject = CareSubject(
        id: targetId,
        ownerUserId: ownerUserId,
        type: mode == ArchiveImportMode.replaceSelectedSubject
            ? existing?.type ?? importedType
            : importedType,
        displayName: subject['displayName'] as String? ?? 'Imported profile',
        relationship: subject['relationship'] as String?,
        profileData: importedProfile,
        createdAt: _dateOr(subject['createdAt'], now),
        updatedAt: now,
      );
      await database.upsertCareSubject(importedSubject);
      await ProfileStore.saveProfile(
        userId: ownerUserId,
        careSubjectId: targetId,
        data: importedProfile,
      );

      final runtimeProfile = _mapOrNull(subject['runtimeProfile']);
      if (runtimeProfile != null && runtimeProfile.isNotEmpty) {
        await database.updateUserProfile(
          userId: targetId,
          presetId: runtimeProfile['preset_id'] as String? ?? 'sage',
          name: runtimeProfile['name'] as String?,
          diagnosis: runtimeProfile['diagnosis'] as String?,
          braceStatus: runtimeProfile['brace_status'] as String?,
          ageRange: runtimeProfile['age_range'] as String?,
        );
      }

      for (final eventMap in sourceEvents) {
        final event = Event.fromJson(eventMap);
        await database.insertEvent(
          event.copyWith(
            id: eventIdMap[event.id] ?? _uuid.v4(),
            userId: targetId,
          ),
        );
      }
      for (final appointmentMap in sourceAppointments) {
        final appointment = Appointment.fromJson(appointmentMap);
        final completedId = appointment.completedEventId == null
            ? null
            : eventIdMap[appointment.completedEventId!];
        await database.insertAppointment(
          appointment.copyWith(
            id: mode == ArchiveImportMode.replaceSelectedSubject
                ? appointment.id
                : _uuid.v4(),
            userId: targetId,
            completedEventId: completedId,
          ),
        );
      }

      importedSubjectIds.add(targetId);
      eventCount += sourceEvents.length;
      appointmentCount += sourceAppointments.length;
      if (originalId.isEmpty) {
        throw const PortableArchiveException(
          'Archive subject identifier is invalid.',
        );
      }
    }

    return ArchiveImportResult(
      importedSubjectIds: importedSubjectIds,
      importedEventCount: eventCount,
      importedAppointmentCount: appointmentCount,
    );
  }

  Future<Map<String, dynamic>> _buildPayload(String ownerUserId) async {
    final subjects = await database.getCareSubjects(ownerUserId);
    final subjectPayloads = <Map<String, dynamic>>[];
    for (final subject in subjects) {
      final profile = await ProfileStore.loadProfile(
        userId: ownerUserId,
        careSubjectId: subject.id,
      );
      final runtimeProfile = await database.getUserProfile(subject.id);
      final events = await database.getEventsByUser(subject.id);
      final appointments = await database.getAppointmentsByUser(subject.id);
      subjectPayloads.add({
        'originalId': subject.id,
        'subjectType': subject.type.name,
        'displayName': subject.displayName,
        'relationship': subject.relationship,
        'createdAt': subject.createdAt.toUtc().toIso8601String(),
        'updatedAt': subject.updatedAt.toUtc().toIso8601String(),
        'profileData': profile.toJson(),
        'runtimeProfile': runtimeProfile,
        'events': events.map((event) => event.toJson()).toList(),
        'appointments': appointments
            .map((appointment) => appointment.toJson())
            .toList(),
        'attachments': {
          'included': <String>[],
          'omitted': [
            if (runtimeProfile?['custom_photo_path'] != null)
              'custom_photo_path',
          ],
        },
      });
    }

    return {
      'format': format,
      'schemaVersion': schemaVersion,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'owner': {'exportedForOwner': ownerUserId},
      'subjects': subjectPayloads,
      'exportScope': {
        'subjectCount': subjectPayloads.length,
        'eventCount': subjectPayloads.fold<int>(
          0,
          (sum, subject) => sum + (subject['events'] as List).length,
        ),
        'appointmentCount': subjectPayloads.fold<int>(
          0,
          (sum, subject) => sum + (subject['appointments'] as List).length,
        ),
      },
      'attachments': {
        'included': <String>[],
        'omitted': ['custom_photo_path'],
      },
    };
  }

  Future<Map<String, dynamic>> _decryptPayload(
    Uint8List archiveBytes,
    String passphrase,
  ) async {
    _validatePassphrase(passphrase);
    try {
      final envelope = _map(jsonDecode(utf8.decode(archiveBytes)));
      if (envelope['format'] != format ||
          envelope['schemaVersion'] != schemaVersion ||
          envelope['cipher'] != cipherName ||
          envelope['kdf'] != kdfName) {
        throw const PortableArchiveException(
          'This is not a supported SpineUp archive.',
        );
      }
      final salt = base64Url.decode(envelope['salt'] as String);
      final nonce = base64Url.decode(envelope['nonce'] as String);
      final mac = base64Url.decode(envelope['mac'] as String);
      final ciphertext = base64Url.decode(envelope['ciphertext'] as String);
      final key = await _deriveKey(passphrase, salt);
      final clearBytes = await AesGcm.with256bits().decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
        aad: _aadFor(salt: salt),
      );
      final payload = _map(jsonDecode(utf8.decode(clearBytes)));
      if (payload['format'] != format ||
          payload['schemaVersion'] != schemaVersion ||
          payload['subjects'] is! List) {
        throw const PortableArchiveException(
          'The archive payload is incomplete or unsupported.',
        );
      }
      return payload;
    } on PortableArchiveException {
      rethrow;
    } catch (_) {
      throw const PortableArchiveException(
        'The passphrase is incorrect or the archive is damaged. No data was imported.',
      );
    }
  }

  ArchivePreview _previewFromPayload(Map<String, dynamic> payload) {
    return ArchivePreview(
      exportedAt: DateTime.parse(payload['exportedAt'] as String),
      schemaVersion: payload['schemaVersion'] as int,
      subjects: _subjectMaps(payload)
          .map((subject) {
            return ArchiveSubjectPreview(
              displayName:
                  subject['displayName'] as String? ?? 'Unnamed profile',
              type: _subjectType(subject),
              relationship: subject['relationship'] as String?,
              eventCount: _eventMaps(subject).length,
              appointmentCount: _appointmentMaps(subject).length,
              hasProfile: subject['profileData'] is Map,
            );
          })
          .toList(growable: false),
      omittedAttachments: _stringList(
        _mapOrNull(payload['attachments'])?['omitted'],
      ),
    );
  }

  Future<SecretKey> _deriveKey(String passphrase, List<int> salt) {
    return Argon2id(
      memory: _argonMemory,
      parallelism: _argonParallelism,
      iterations: _argonIterations,
      hashLength: _argonHashLength,
    ).deriveKeyFromPassword(password: passphrase, nonce: salt);
  }

  List<int> _aadFor({required List<int> salt}) {
    return utf8.encode(
      jsonEncode({
        'format': format,
        'schemaVersion': schemaVersion,
        'cipher': cipherName,
        'kdf': kdfName,
        'salt': base64UrlEncode(salt),
      }),
    );
  }

  void _validatePassphrase(String passphrase) {
    if (passphrase.trim().length < 12) {
      throw const PortableArchiveException(
        'Use a passphrase with at least 12 characters. SpineUp cannot recover it if it is forgotten.',
      );
    }
  }

  List<int> _secureRandomBytes(int length) {
    final random = math.Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  List<Map<String, dynamic>> _subjectMaps(Map<String, dynamic> payload) {
    return (payload['subjects'] as List<dynamic>)
        .map((subject) => _map(subject))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _eventMaps(Map<String, dynamic> subject) {
    return (subject['events'] as List<dynamic>? ?? const [])
        .map((event) => _map(event))
        .toList(growable: false);
  }

  List<Map<String, dynamic>> _appointmentMaps(Map<String, dynamic> subject) {
    return (subject['appointments'] as List<dynamic>? ?? const [])
        .map((appointment) => _map(appointment))
        .toList(growable: false);
  }

  CareSubjectType _subjectType(Map<String, dynamic> subject) {
    return CareSubjectType.values.firstWhere(
      (value) => value.name == subject['subjectType'],
      orElse: () => CareSubjectType.ward,
    );
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is! Map) {
      throw const PortableArchiveException('Archive structure is invalid.');
    }
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic>? _mapOrNull(dynamic value) {
    if (value == null) return null;
    if (value is! Map) return null;
    return Map<String, dynamic>.from(value);
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  DateTime _dateOr(dynamic value, DateTime fallback) {
    if (value is! String) return fallback;
    return DateTime.tryParse(value) ?? fallback;
  }
}
