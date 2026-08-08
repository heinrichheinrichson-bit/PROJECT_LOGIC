import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/cloud_sync.dart';
import 'package:project_logic_prototype/data_backup.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('first synchronization uploads local progress', () async {
    SharedPreferences.setMockInitialValues({'progress': 'local'});
    final provider = MemoryCloudProvider();
    final service = CloudSyncService(provider: provider);

    expect((await service.assess()).status, CloudSyncStatus.noRemoteData);
    await service.synchronize();

    expect(provider.snapshot, isNotNull);
    expect((await service.assess()).status, CloudSyncStatus.inSync);
  });

  test('a cloud-only change is downloaded with rollback protection', () async {
    SharedPreferences.setMockInitialValues({'progress': 'base'});
    final provider = MemoryCloudProvider();
    final service = CloudSyncService(provider: provider);
    await service.synchronize();

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('progress', 'cloud-change');
    final cloudBackup = await const DataBackupService().createBackup();
    final cloudFingerprint =
        await const DataBackupService().contentFingerprint();
    await preferences.setString('progress', 'base');
    await provider.upload(
      CloudSnapshot(
        backup: cloudBackup,
        fingerprint: cloudFingerprint,
        revision: '',
        uploadedAt: DateTime.utc(2026, 8, 8),
      ),
      expectedRevision: provider.snapshot!.revision,
    );

    expect(
      (await service.assess()).status,
      CloudSyncStatus.downloadRecommended,
    );
    await service.synchronize();
    expect(preferences.getString('progress'), 'cloud-change');
    expect(await const DataBackupService().hasRecoveryBackup(), isTrue);
  });

  test('independent local and cloud changes produce an explicit conflict',
      () async {
    SharedPreferences.setMockInitialValues({'progress': 'base'});
    final provider = MemoryCloudProvider();
    final service = CloudSyncService(provider: provider);
    await service.synchronize();
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString('progress', 'cloud-change');
    final cloudBackup = await const DataBackupService().createBackup();
    final cloudFingerprint =
        await const DataBackupService().contentFingerprint();
    await preferences.setString('progress', 'local-change');
    await provider.upload(
      CloudSnapshot(
        backup: cloudBackup,
        fingerprint: cloudFingerprint,
        revision: '',
        uploadedAt: DateTime.utc(2026, 8, 8),
      ),
      expectedRevision: provider.snapshot!.revision,
    );

    expect((await service.assess()).status, CloudSyncStatus.conflict);
    await expectLater(
      service.synchronize(),
      throwsA(isA<CloudRevisionConflict>()),
    );
    expect(preferences.getString('progress'), 'local-change');

    await service.synchronize(conflictChoice: CloudConflictChoice.keepCloud);
    expect(preferences.getString('progress'), 'cloud-change');
  });

  test('stale upload revisions cannot overwrite another device', () async {
    SharedPreferences.setMockInitialValues({'progress': 'first'});
    final provider = MemoryCloudProvider();
    final service = CloudSyncService(provider: provider);
    final first = await service.uploadLocal();
    await provider.upload(
      first,
      expectedRevision: first.revision,
    );

    await expectLater(
      service.uploadLocal(expectedRevision: first.revision),
      throwsA(isA<CloudRevisionConflict>()),
    );
  });

  test('cloud snapshots have a versioned validated storage format', () {
    final uploadedAt = DateTime.utc(2026, 8, 8, 14, 30);
    final snapshot = CloudSnapshot(
      backup: '{"backup":true}',
      fingerprint: 'a1b2c3d4',
      revision: 'revision-7',
      uploadedAt: uploadedAt,
    );

    final restored = CloudSnapshot.fromJson(snapshot.toJson());
    expect(restored.backup, snapshot.backup);
    expect(restored.fingerprint, snapshot.fingerprint);
    expect(restored.revision, snapshot.revision);
    expect(restored.uploadedAt, uploadedAt);
    expect(
      () => CloudSnapshot.fromJson({...snapshot.toJson(), 'revision': ''}),
      throwsFormatException,
    );
    expect(
      () => CloudSnapshot.fromJson({...snapshot.toJson(), 'schemaVersion': 2}),
      throwsFormatException,
    );
  });
}

class MemoryCloudProvider implements CloudStorageProvider {
  CloudSnapshot? snapshot;
  var _revision = 0;

  @override
  Future<CloudSnapshot?> download() async => snapshot;

  @override
  Future<CloudSnapshot> upload(
    CloudSnapshot candidate, {
    String? expectedRevision,
  }) async {
    if (snapshot != null && expectedRevision != snapshot!.revision) {
      throw const CloudRevisionConflict();
    }
    _revision++;
    snapshot = CloudSnapshot(
      backup: candidate.backup,
      fingerprint: candidate.fingerprint,
      revision: 'r$_revision',
      uploadedAt: candidate.uploadedAt,
    );
    return snapshot!;
  }
}
