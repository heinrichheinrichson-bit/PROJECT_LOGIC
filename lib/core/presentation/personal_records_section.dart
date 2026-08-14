import 'package:flutter/material.dart';

import '../../app_localizations.dart';
import '../formatters/duration_formatter.dart';
import '../statistics/personal_records.dart';

class PersonalRecordsSection extends StatelessWidget {
  const PersonalRecordsSection({required this.records, super.key});
  final PersonalRecords records;

  @override
  Widget build(BuildContext context) {
    final strings = context.strings;
    final items = _items(context, records);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(strings.text('Deine Rekorde', 'Your records'),
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => PersonalRecordsScreen(records: records),
                ),
              ),
              child: Text(strings.text('Alle ansehen', 'View all')),
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
  Widget build(BuildContext context) {
    final strings = context.strings;
    return Scaffold(
      appBar:
          AppBar(title: Text(strings.text('Deine Rekorde', 'Your records'))),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(strings.text(
            'Persönliche Bestleistungen aus deinem bisherigen Spielverlauf.',
            'Personal bests from all the puzzles you have played so far.',
          )),
          const SizedBox(height: 16),
          for (final item in _items(context, records)) _RecordTile(item: item),
          if (records.fastestByGame.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(strings.text('Schnellste Rätsel', 'Fastest puzzles'),
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final speed in records.fastestByGame)
              _RecordTile(
                item: _RecordItem(
                  Icons.speed_rounded,
                  _gameLabel(context, speed.gameType.label),
                  formatClockDuration(speed.seconds),
                  _date(context, speed.date),
                ),
              ),
          ],
        ],
      ),
    );
  }
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

List<_RecordItem> _items(BuildContext context, PersonalRecords records) {
  final strings = context.strings;
  return [
    if (records.longestStreak case final record?)
      _RecordItem(
        Icons.local_fire_department_rounded,
        strings.text('Längste Spielserie', 'Longest streak'),
        strings.plural(record.value, '1 Tag', '${record.value} Tage', '1 day',
            '${record.value} days'),
        '${_date(context, record.start)} – ${_date(context, record.end!)}',
      ),
    if (records.mostXp case final record?)
      _RecordItem(
          Icons.bolt_rounded,
          strings.text('Meiste XP an einem Tag', 'Most XP in one day'),
          '${record.value} XP',
          _date(context, record.start)),
    if (records.mostPuzzles case final record?)
      _RecordItem(
          Icons.extension_rounded,
          strings.text('Meiste Rätsel an einem Tag', 'Most puzzles in one day'),
          '${record.value}',
          _date(context, record.start)),
    if (records.longestPlaytime case final record?)
      _RecordItem(
          Icons.timer_outlined,
          strings.text(
              'Längste Spielzeit an einem Tag', 'Longest playtime in one day'),
          formatClockDuration(record.value),
          _date(context, record.start)),
    if (records.mostGameTypes case final record?)
      _RecordItem(
          Icons.dashboard_customize_outlined,
          strings.text(
              'Meiste Spielarten an einem Tag', 'Most game types in one day'),
          '${record.value}',
          _date(context, record.start)),
    if (records.strongestMonth case final record?)
      _RecordItem(
          Icons.calendar_month_rounded,
          strings.text('Stärkster Monat', 'Strongest month'),
          '${record.value} ${strings.text('Rätsel', 'puzzles')}',
          _month(context, record.start)),
    _RecordItem(
        Icons.ac_unit_rounded,
        strings.text('Eingesetzte Eiszapfen', 'Streak freezes used'),
        '${records.usedFreezes}',
        strings.text(
            'Automatisch geschützte Tage', 'Automatically protected days')),
  ];
}

String _date(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatCompactDate(date);
String _month(BuildContext context, DateTime date) =>
    MaterialLocalizations.of(context).formatMonthYear(date);

String _gameLabel(BuildContext context, String label) => switch (label) {
      'Zelte & Bäume' => context.strings.text('Zelte & Bäume', 'Tents & Trees'),
      _ => label,
    };
