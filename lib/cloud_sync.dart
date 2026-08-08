import 'package:shared_preferences/shared_preferences.dart';

import 'data_backup.dart';

class CloudSnapshot {
  static const schemaVersion = 1;

  const CloudSnapshot({
    required this.backup,
    required this.fingerprint,
    required this.revision,
    required this.uploadedAt,
  });

  final String backup;
  final String fingerprint;
  final String revision;
  final DateTime uploadedAt;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'backup': backup,
        'fingerprint': fingerprint,
        'revision': revision,
        'uploadedAt': uploadedAt.toUtc().toIso8601String(),
      };

  factory CloudSnapshot.fromJson(Map<String, Object?> json) {
    final version = json['schemaVersion'];
    final backup = json['backup'];
    final fingerprint = json['fingerprint'];
    final revision = json['revision'];
    final uploadedAt = DateTime.tryParse(json['uploadedAt'] as String? ?? '');
    if (version != schemaVersion ||
        backup is! String ||
        backup.isEmpty ||
        fingerprint is! String ||
        fingerprint.isEmpty ||
        revision is! String ||
        revision.isEmpty ||
        uploadedAt == null) {
      throw const FormatException('Ungültiger Cloud-Speicherstand.');
    }
    return CloudSnapshot(
      backup: backup,
      fingerprint: fingerprint,
      revision: revision,
      uploadedAt: uploadedAt.toUtc(),
    );
  }
}

abstract interface class CloudStorageProvider {
  Future<CloudSnapshot?> download();

  /// Uploads only if [expectedRevision] is still current. Providers must throw
  /// [CloudRevisionConflict] if another device changed the remote snapshot.
  Future<CloudSnapshot> upload(
    CloudSnapshot snapshot, {
    String? expectedRevision,
  });
}

class CloudRevisionConflict implements Exception {
  const CloudRevisionConflict();

  @override
  String toString() =>
      'Der Cloud-Stand wurde auf einem anderen Gerät geändert.';
}

enum CloudSyncStatus {
  noRemoteData,
  inSync,
  uploadRecommended,
  downloadRecommended,
  conflict,
}

class CloudSyncAssessment {
  const CloudSyncAssessment({
    required this.status,
    required this.localFingerprint,
    required this.baseFingerprint,
    required this.remote,
  });

  final CloudSyncStatus status;
  final String localFingerprint;
  final String? baseFingerprint;
  final CloudSnapshot? remote;
}

enum CloudConflictChoice { keepLocal, keepCloud }

/// Provider-independent synchronization with three-way conflict detection.
///
/// The last synchronized fingerprint is the common base. This makes it
/// possible to distinguish an ordinary one-sided update from two devices that
/// both changed independently. Conflicts are never resolved silently.
class CloudSyncService {
  const CloudSyncService({
    required this.provider,
    this.backups = const DataBackupService(),
  });

  static const _baseFingerprintKey = '_cloud_base_fingerprint_v1';
  static const _lastSyncAtKey = '_cloud_last_sync_at_v1';

  final CloudStorageProvider provider;
  final DataBackupService backups;

  Future<CloudSyncAssessment> assess() async {
    final preferences = await SharedPreferences.getInstance();
    final local = await backups.contentFingerprint();
    final base = preferences.getString(_baseFingerprintKey);
    final remote = await provider.download();

    if (remote == null) {
      return CloudSyncAssessment(
        status: CloudSyncStatus.noRemoteData,
        localFingerprint: local,
        baseFingerprint: base,
        remote: null,
      );
    }
    if (remote.fingerprint == local) {
      await _rememberBase(remote.fingerprint);
      return CloudSyncAssessment(
        status: CloudSyncStatus.inSync,
        localFingerprint: local,
        baseFingerprint: remote.fingerprint,
        remote: remote,
      );
    }

    final status = switch ((base, local == base, remote.fingerprint == base)) {
      (null, _, _) => CloudSyncStatus.conflict,
      (_, true, false) => CloudSyncStatus.downloadRecommended,
      (_, false, true) => CloudSyncStatus.uploadRecommended,
      _ => CloudSyncStatus.conflict,
    };
    return CloudSyncAssessment(
      status: status,
      localFingerprint: local,
      baseFingerprint: base,
      remote: remote,
    );
  }

  Future<CloudSnapshot> uploadLocal({String? expectedRevision}) async {
    final fingerprint = await backups.contentFingerprint();
    final candidate = CloudSnapshot(
      backup: await backups.createBackup(),
      fingerprint: fingerprint,
      revision: '',
      uploadedAt: DateTime.now().toUtc(),
    );
    final uploaded = await provider.upload(
      candidate,
      expectedRevision: expectedRevision,
    );
    await _rememberBase(uploaded.fingerprint);
    return uploaded;
  }

  Future<void> downloadCloud(CloudSnapshot snapshot) async {
    backups.inspect(snapshot.backup);
    await backups.restoreBackup(snapshot.backup);
    final restoredFingerprint = await backups.contentFingerprint();
    if (restoredFingerprint != snapshot.fingerprint) {
      await backups.restoreRecoveryBackup();
      throw const BackupValidationException(
        'Cloud-Sicherung und Prüfsumme passen nicht zusammen.',
      );
    }
    await _rememberBase(snapshot.fingerprint);
  }

  Future<void> synchronize({CloudConflictChoice? conflictChoice}) async {
    final assessment = await assess();
    switch (assessment.status) {
      case CloudSyncStatus.noRemoteData:
      case CloudSyncStatus.uploadRecommended:
        await uploadLocal(expectedRevision: assessment.remote?.revision);
        return;
      case CloudSyncStatus.downloadRecommended:
        await downloadCloud(assessment.remote!);
        return;
      case CloudSyncStatus.inSync:
        return;
      case CloudSyncStatus.conflict:
        switch (conflictChoice) {
          case CloudConflictChoice.keepLocal:
            await uploadLocal(expectedRevision: assessment.remote?.revision);
            return;
          case CloudConflictChoice.keepCloud:
            await downloadCloud(assessment.remote!);
            return;
          case null:
            throw const CloudRevisionConflict();
        }
    }
  }

  Future<DateTime?> lastSyncAt() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_lastSyncAtKey);
    return raw == null ? null : DateTime.tryParse(raw)?.toLocal();
  }

  Future<void> _rememberBase(String fingerprint) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_baseFingerprintKey, fingerprint);
    await preferences.setString(
      _lastSyncAtKey,
      DateTime.now().toUtc().toIso8601String(),
    );
  }
}
