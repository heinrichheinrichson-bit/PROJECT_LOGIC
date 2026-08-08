enum ExperienceEventKind {
  puzzleCompleted,
  achievementUnlocked,
  missionCompleted,
}

/// Append-only XP entry. The awarded amount is stored, not recalculated, so
/// balancing changes never remove XP a player already earned.
class ExperienceEvent {
  const ExperienceEvent({
    required this.id,
    required this.kind,
    required this.points,
    required this.occurredAt,
    this.referenceId,
  });

  static const int schemaVersion = 1;

  final String id;
  final ExperienceEventKind kind;
  final int points;
  final DateTime occurredAt;
  final String? referenceId;

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'id': id,
        'kind': kind.name,
        'points': points,
        'occurredAt': occurredAt.toIso8601String(),
        if (referenceId != null) 'referenceId': referenceId,
      };

  factory ExperienceEvent.fromJson(Map<String, Object?> json) {
    if ((json['schemaVersion'] as num?)?.toInt() != schemaVersion) {
      throw const FormatException('Unsupported XP event version.');
    }
    final id = json['id'];
    final points = (json['points'] as num?)?.toInt();
    final occurredAt = DateTime.tryParse(json['occurredAt'] as String? ?? '');
    if (id is! String ||
        id.isEmpty ||
        points == null ||
        points < 0 ||
        occurredAt == null) {
      throw const FormatException('Invalid XP event.');
    }
    return ExperienceEvent(
      id: id,
      kind: ExperienceEventKind.values.firstWhere(
        (value) => value.name == json['kind'],
        orElse: () => throw const FormatException('Unknown XP event kind.'),
      ),
      points: points,
      occurredAt: occurredAt,
      referenceId: json['referenceId'] as String?,
    );
  }
}
