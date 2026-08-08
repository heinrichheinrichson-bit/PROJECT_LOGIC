import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class BackupSummary {
  const BackupSummary({
    required this.createdAt,
    required this.entryCount,
    required this.schemaVersion,
  });

  final DateTime createdAt;
  final int entryCount;
  final int schemaVersion;
}

class BackupValidationException implements Exception {
  const BackupValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Creates a portable, versioned snapshot of all durable Project Logic data.
///
/// The envelope is intentionally independent of Google Drive. The same payload
/// can be copied manually today and uploaded by a cloud provider later.
class DataBackupService {
  const DataBackupService();

  static const schemaVersion = 1;
  static const format = 'project-logic-backup';
  static const _recoveryKey = '_backup_recovery_v1';

  Future<String> createBackup({DateTime? createdAt}) async {
    final preferences = await SharedPreferences.getInstance();
    final entries = _readPortableEntries(preferences);
    final payload = <String, Object?>{
      'format': format,
      'schemaVersion': schemaVersion,
      'createdAt': (createdAt ?? DateTime.now()).toUtc().toIso8601String(),
      'entries': entries,
    };
    final canonicalPayload = jsonEncode(payload);
    return jsonEncode({
      ...payload,
      'checksum': _checksum(canonicalPayload),
    });
  }

  /// Identifies the durable user data without depending on backup time.
  /// Internal rollback and cloud bookkeeping values are intentionally ignored.
  Future<String> contentFingerprint() async {
    final preferences = await SharedPreferences.getInstance();
    return _checksum(jsonEncode(_readPortableEntries(preferences)));
  }

  static Map<String, Object?> _readPortableEntries(
    SharedPreferences preferences,
  ) {
    final entries = <String, Object?>{};
    final keys = preferences
        .getKeys()
        .where(
          (key) => !key.startsWith('_backup_') && !key.startsWith('_cloud_'),
        )
        .toList()
      ..sort();
    for (final key in keys) {
      entries[key] = _encodeValue(preferences.get(key));
    }
    return entries;
  }

  BackupSummary inspect(String rawBackup) {
    final envelope = _decodeAndValidate(rawBackup);
    return BackupSummary(
      createdAt: DateTime.parse(envelope['createdAt']! as String).toLocal(),
      entryCount: (envelope['entries']! as Map).length,
      schemaVersion: envelope['schemaVersion']! as int,
    );
  }

  /// Restores only after the complete payload has passed validation. If a
  /// platform write fails, the previous preferences snapshot is restored.
  Future<BackupSummary> restoreBackup(String rawBackup) async {
    final envelope = _decodeAndValidate(rawBackup);
    final encodedEntries =
        Map<String, Object?>.from(envelope['entries']! as Map);
    final decodedEntries = <String, Object?>{
      for (final entry in encodedEntries.entries)
        entry.key: _decodeValue(entry.value),
    };
    final preferences = await SharedPreferences.getInstance();
    final rollback = await createBackup();
    try {
      await preferences.clear();
      await _writeEntries(preferences, decodedEntries);
      await preferences.setString(_recoveryKey, rollback);
    } on Object {
      final previous = _decodeAndValidate(rollback);
      final previousEntries = Map<String, Object?>.from(
        previous['entries']! as Map,
      );
      await preferences.clear();
      await _writeEntries(preferences, {
        for (final entry in previousEntries.entries)
          entry.key: _decodeValue(entry.value),
      });
      rethrow;
    }
    return BackupSummary(
      createdAt: DateTime.parse(envelope['createdAt']! as String).toLocal(),
      entryCount: decodedEntries.length,
      schemaVersion: schemaVersion,
    );
  }

  Future<bool> hasRecoveryBackup() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_recoveryKey) != null;
  }

  Future<BackupSummary> restoreRecoveryBackup() async {
    final preferences = await SharedPreferences.getInstance();
    final backup = preferences.getString(_recoveryKey);
    if (backup == null) {
      throw const BackupValidationException(
        'Es ist keine lokale Sicherheitskopie vorhanden.',
      );
    }
    return restoreBackup(backup);
  }

  Map<String, Object?> _decodeAndValidate(String rawBackup) {
    try {
      final decoded = Map<String, Object?>.from(jsonDecode(rawBackup) as Map);
      if (decoded['format'] != format) {
        throw const BackupValidationException('Unbekanntes Sicherungsformat.');
      }
      if (decoded['schemaVersion'] != schemaVersion) {
        throw const BackupValidationException(
          'Diese Sicherungsversion wird noch nicht unterstützt.',
        );
      }
      DateTime.parse(decoded['createdAt']! as String);
      final entries = Map<String, Object?>.from(decoded['entries']! as Map);
      for (final entry in entries.entries) {
        if (entry.key.trim().isEmpty) {
          throw const BackupValidationException('Ungültiger Datenschlüssel.');
        }
        _decodeValue(entry.value);
      }
      final checksum = decoded.remove('checksum');
      if (checksum is! String || checksum != _checksum(jsonEncode(decoded))) {
        throw const BackupValidationException(
          'Die Sicherung ist beschädigt oder unvollständig.',
        );
      }
      return decoded;
    } on BackupValidationException {
      rethrow;
    } on Object {
      throw const BackupValidationException(
        'Die Sicherung konnte nicht gelesen werden.',
      );
    }
  }

  static Object _encodeValue(Object? value) {
    if (value is String) return {'type': 'string', 'value': value};
    if (value is bool) return {'type': 'bool', 'value': value};
    if (value is int) return {'type': 'int', 'value': value};
    if (value is double) return {'type': 'double', 'value': value};
    if (value is List<String>) return {'type': 'stringList', 'value': value};
    throw const BackupValidationException('Nicht unterstützter Datentyp.');
  }

  static Object _decodeValue(Object? encoded) {
    final item = Map<String, Object?>.from(encoded as Map);
    final value = item['value'];
    return switch (item['type']) {
      'string' when value is String => value,
      'bool' when value is bool => value,
      'int' when value is int => value,
      'double' when value is num => value.toDouble(),
      'stringList' when value is List => value.cast<String>(),
      _ => throw const BackupValidationException(
          'Die Sicherung enthält ungültige Daten.',
        ),
    };
  }

  static Future<void> _writeEntries(
    SharedPreferences preferences,
    Map<String, Object?> entries,
  ) async {
    for (final entry in entries.entries) {
      final value = entry.value;
      final success = switch (value) {
        String value => await preferences.setString(entry.key, value),
        bool value => await preferences.setBool(entry.key, value),
        int value => await preferences.setInt(entry.key, value),
        double value => await preferences.setDouble(entry.key, value),
        List<String> value => await preferences.setStringList(entry.key, value),
        _ => false,
      };
      if (!success) {
        throw StateError('Sicherung konnte nicht geschrieben werden.');
      }
    }
  }

  /// Adler-32 is used for accidental-corruption detection, not security.
  static String _checksum(String value) {
    var a = 1;
    var b = 0;
    for (final byte in utf8.encode(value)) {
      a = (a + byte) % 65521;
      b = (b + a) % 65521;
    }
    return (b * 65536 + a).toRadixString(16).padLeft(8, '0');
  }
}
