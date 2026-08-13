import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'data_backup.dart';
import 'game_storage.dart';

enum AppDataMigrationStatus { current, migrated, newerDataPreserved }

/// Runs durable-data upgrades before any repository reads user progress.
///
/// Every migration is backed up first and the schema marker is written last.
/// A failed migration therefore restores the exact previous durable state and
/// will be retried on the next launch instead of leaving partially upgraded
/// data behind.
class AppDataMigrationService {
  const AppDataMigrationService({
    this.backups = const DataBackupService(),
  });

  static const currentSchemaVersion = 1;
  static const _schemaVersionKey = '_app_data_schema_version';
  static const _migrationRecoveryKey = '_app_data_migration_recovery_v1';

  final DataBackupService backups;

  Future<AppDataMigrationStatus> migrate() async {
    final preferences = await SharedPreferences.getInstance();
    final storedVersion = preferences.getInt(_schemaVersionKey) ?? 0;
    if (storedVersion == currentSchemaVersion) {
      return AppDataMigrationStatus.current;
    }
    if (storedVersion > currentSchemaVersion) {
      return AppDataMigrationStatus.newerDataPreserved;
    }

    final rollback = await backups.createBackup();
    try {
      for (var version = storedVersion + 1;
          version <= currentSchemaVersion;
          version++) {
        await _runMigration(version, preferences);
      }
      await preferences.setString(_migrationRecoveryKey, rollback);
      await preferences.setInt(_schemaVersionKey, currentSchemaVersion);
      return AppDataMigrationStatus.migrated;
    } on Object {
      await backups.restoreBackup(rollback);
      rethrow;
    }
  }

  Future<void> _runMigration(
    int version,
    SharedPreferences preferences,
  ) async {
    switch (version) {
      case 1:
        await _canonicalizeLegacyBinaryData(preferences);
    }
  }

  Future<void> _canonicalizeLegacyBinaryData(
    SharedPreferences preferences,
  ) async {
    const activeGameKey = 'active_binary_game_v1';
    final activeGame = preferences.getString(activeGameKey);
    if (activeGame != null) {
      try {
        final decoded =
            Map<String, Object?>.from(jsonDecode(activeGame) as Map);
        final canonical = SavedGame.fromJson(decoded);
        await _requireWrite(
          preferences.setString(activeGameKey, jsonEncode(canonical.toJson())),
        );
      } on FormatException {
        // Preserve unreadable legacy data for the existing recovery path.
      } on TypeError {
        // Preserve unreadable legacy data for the existing recovery path.
      }
    }

    const resultsKey = 'binary_results_v1';
    final results = preferences.getString(resultsKey);
    if (results != null) {
      try {
        final decoded = jsonDecode(results) as List<dynamic>;
        final canonical = decoded.map((item) {
          return PuzzleResult.fromJson(
            Map<String, Object?>.from(item as Map),
          ).toJson();
        }).toList(growable: false);
        await _requireWrite(
          preferences.setString(resultsKey, jsonEncode(canonical)),
        );
      } on FormatException {
        // Preserve unreadable legacy data instead of blocking app startup.
      } on TypeError {
        // Preserve unreadable legacy data instead of blocking app startup.
      }
    }
  }

  static Future<void> _requireWrite(Future<bool> operation) async {
    if (!await operation) {
      throw StateError('Datenmigration konnte nicht gespeichert werden.');
    }
  }
}
