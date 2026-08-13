import 'package:flutter/material.dart';

import '../formatters/duration_formatter.dart';
import '../statistics/personal_records.dart';

class PersonalRecordsSection extends StatelessWidget {
  const PersonalRecordsSection({required this.records, super.key});
  final PersonalRecords records;

  @override
  Widget build(BuildContext context) {
    final items = _items(records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Deine Rekorde',
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PersonalRecordsScreen(records: records),
                ),
              ),
              child: const Text('Alle ansehen'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final item in items.take(3)) _RecordTile(item: item),
      ],
    );
  }
}

class PersonalRecordsScreen extends StatelessWidget {
  const PersonalRecordsScreen({required this.records, super.key});
  final PersonalRecords records;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Deine Rekorde')),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Persönliche Bestleistungen aus deinem bisherigen Spielverlauf.',
            ),
            const SizedBox(height: 16),
            for (final item in _items(records)) _RecordTile(item: item),
            if (records.fastestByGame.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text('Schnellste Rätsel',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              for (final speed in records.fastestByGame)
                _RecordTile(
                  item: _RecordItem(
                    Icons.speed_rounded,
                    speed.gameType.label,
                    formatClockDuration(speed.seconds),
                    _date(speed.date),
                  ),
                ),
            ],
          ],
        ),
      );
}

class _RecordItem {
  const _RecordItem(this.icon, this.title, this.value, this.detail);
  final IconData icon;
  final String title;
  final String value;
  final String detail;
}

class _RecordTile extends StatelessWidget {
  const _RecordTile({required this.item});
  final _RecordItem item;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(item.icon)),
          title: Text(item.title),
          subtitle: Text(item.detail),
          trailing: Text(item.value,
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      );
}

List<_RecordItem> _items(PersonalRecords records) => [
      if (records.longestStreak case final record?)
        _RecordItem(
          Icons.local_fire_department_rounded,
          'Längste Spielserie',
          '${record.value} Tage',
          '${_date(record.start)} – ${_date(record.end!)}',
        ),
      if (records.mostXp case final record?)
        _RecordItem(Icons.bolt_rounded, 'Meiste XP an einem Tag',
            '${record.value} XP', _date(record.start)),
      if (records.mostPuzzles case final record?)
        _RecordItem(Icons.extension_rounded, 'Meiste Rätsel an einem Tag',
            '${record.value}', _date(record.start)),
      if (records.longestPlaytime case final record?)
        _RecordItem(Icons.timer_outlined, 'Längste Spielzeit an einem Tag',
            formatClockDuration(record.value), _date(record.start)),
      if (records.mostGameTypes case final record?)
        _RecordItem(
            Icons.dashboard_customize_outlined,
            'Meiste Spielarten an einem Tag',
            '${record.value}',
            _date(record.start)),
      if (records.strongestMonth case final record?)
        _RecordItem(Icons.calendar_month_rounded, 'Stärkster Monat',
            '${record.value} Rätsel', _month(record.start)),
      _RecordItem(Icons.ac_unit_rounded, 'Eingesetzte Eiszapfen',
          '${records.usedFreezes}', 'Automatisch geschützte Tage'),
    ];

String _date(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
String _month(DateTime date) => '${const [
      'Januar',
      'Februar',
      'März',
      'April',
      'Mai',
      'Juni',
      'Juli',
      'August',
      'September',
      'Oktober',
      'November',
      'Dezember'
    ][date.month - 1]} ${date.year}';
