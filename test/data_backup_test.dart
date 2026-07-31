import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/data_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('backup round trip restores every supported preference type', () async {
    SharedPreferences.setMockInitialValues({
      'progress': '{"solved":42}',
      'premium': true,
      'count': 42,
      'ratio': 1.5,
      'days': <String>['2026-07-30', '2026-07-31'],
    });
    const service = DataBackupService();
    final backup = await service.createBackup(
      createdAt: DateTime.utc(2026, 7, 31, 20),
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    await preferences.setString('unwanted', 'newer local data');

    final summary = await service.restoreBackup(backup);

    expect(summary.entryCount, 5);
    expect(preferences.getString('progress'), '{"solved":42}');
    expect(preferences.getBool('premium'), isTrue);
    expect(preferences.getInt('count'), 42);
    expect(preferences.getDouble('ratio'), 1.5);
    expect(preferences.getStringList('days'), hasLength(2));
    expect(preferences.containsKey('unwanted'), isFalse);
  });

  test('tampered backup is rejected before local data changes', () async {
    SharedPreferences.setMockInitialValues({'progress': 'safe'});
    const service = DataBackupService();
    final backup = await service.createBackup();
    final tampered = backup.replaceFirst('safe', 'lost');

    await expectLater(
      service.restoreBackup(tampered),
      throwsA(isA<BackupValidationException>()),
    );
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('progress'), 'safe');
  });

  test('inspect exposes metadata without restoring data', () async {
    SharedPreferences.setMockInitialValues({'progress': 'safe'});
    const service = DataBackupService();
    final backup = await service.createBackup(
      createdAt: DateTime.utc(2026, 7, 31, 20),
    );

    final summary = service.inspect(backup);

    expect(summary.schemaVersion, 1);
    expect(summary.entryCount, 1);
    expect(summary.createdAt.toUtc(), DateTime.utc(2026, 7, 31, 20));
  });
}
