import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/app_data_migration.dart';
import 'package:project_logic_prototype/data_backup.dart';
import 'package:project_logic_prototype/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('legacy data is upgraded before the schema marker is stored', () async {
    SharedPreferences.setMockInitialValues({
      'active_binary_game_v1': jsonEncode({
        'puzzleId': 'easy-01',
        'elapsedSeconds': 7,
        'values': [null, 0, 1],
        'savedAt': '2026-07-30T12:00:00.000',
      }),
      'binary_results_v1': jsonEncode([
        {
          'puzzleId': 'easy-01',
          'bestSeconds': 42,
          'completedAt': '2026-07-31T00:00:00.000',
        }
      ]),
    });

    final status = await const AppDataMigrationService().migrate();
    final preferences = await SharedPreferences.getInstance();
    final savedGame = jsonDecode(
      preferences.getString('active_binary_game_v1')!,
    ) as Map<String, dynamic>;
    final result = (jsonDecode(
      preferences.getString('binary_results_v1')!,
    ) as List<dynamic>)
        .single as Map<String, dynamic>;

    expect(status, AppDataMigrationStatus.migrated);
    expect(savedGame['schemaVersion'], SavedGame.currentSchemaVersion);
    expect(result['gameType'], GameType.binairo.name);
    expect(result['completionCount'], 1);
    expect(
      preferences.getInt('_app_data_schema_version'),
      AppDataMigrationService.currentSchemaVersion,
    );
    expect(
      preferences.getString('_app_data_migration_recovery_v1'),
      isNotEmpty,
    );
  });

  test('migration is idempotent after reaching the current version', () async {
    const service = AppDataMigrationService();
    expect(await service.migrate(), AppDataMigrationStatus.migrated);
    expect(await service.migrate(), AppDataMigrationStatus.current);
  });

  test('migration bookkeeping never enters portable backups', () async {
    SharedPreferences.setMockInitialValues({'progress': 'keep-me'});
    await const AppDataMigrationService().migrate();

    final backup = await const DataBackupService().createBackup();

    expect(backup, contains('progress'));
    expect(backup, isNot(contains('_app_data_')));
  });

  test('newer app data is preserved without downgrade migration', () async {
    SharedPreferences.setMockInitialValues({
      '_app_data_schema_version':
          AppDataMigrationService.currentSchemaVersion + 1,
      'future-data': 'keep-me',
    });

    final status = await const AppDataMigrationService().migrate();
    final preferences = await SharedPreferences.getInstance();

    expect(status, AppDataMigrationStatus.newerDataPreserved);
    expect(preferences.getString('future-data'), 'keep-me');
  });

  test('invalid legacy data is preserved without blocking app startup',
      () async {
    const invalid = '{not-json';
    SharedPreferences.setMockInitialValues({
      'active_binary_game_v1': invalid,
      'unrelated-progress': 'keep-me',
    });

    final status = await const AppDataMigrationService().migrate();
    final preferences = await SharedPreferences.getInstance();

    expect(status, AppDataMigrationStatus.migrated);
    expect(preferences.getString('active_binary_game_v1'), invalid);
    expect(preferences.getString('unrelated-progress'), 'keep-me');
    expect(
      preferences.getInt('_app_data_schema_version'),
      AppDataMigrationService.currentSchemaVersion,
    );
  });
}
