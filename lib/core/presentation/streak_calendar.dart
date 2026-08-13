import 'package:flutter/material.dart';

import '../../game_storage.dart';

class StreakCalendarCard extends StatefulWidget {
  const StreakCalendarCard({required this.progress, super.key});

  final PlayerProgress progress;

  @override
  State<StreakCalendarCard> createState() => _StreakCalendarCardState();
}

class _StreakCalendarCardState extends State<StreakCalendarCard> {
  late DateTime _month = _monthOnly(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final today = _dateOnly(DateTime.now());
    final first = DateTime(_month.year, _month.month, 1);
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - DateTime.monday;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department_rounded,
                    color: colors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.progress.currentStreak} Tage Spielserie',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text('Beste Serie: ${widget.progress.bestStreak} Tage'),
                    ],
                  ),
                ),
                _FreezeBadge(progress: widget.progress),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  tooltip: 'Vorheriger Monat',
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    '${_monthName(_month.month)} ${_month.year}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Nächster Monat',
                  onPressed:
                      _month.year == today.year && _month.month == today.month
                          ? null
                          : () => setState(() =>
                              _month = DateTime(_month.year, _month.month + 1)),
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            Row(
              children: [
                for (final label in ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])
                  Expanded(
                    child: Text(label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: leading + count,
              itemBuilder: (context, index) {
                if (index < leading) return const SizedBox.shrink();
                final day =
                    DateTime(_month.year, _month.month, index - leading + 1);
                return _StreakDay(
                  day: day,
                  today: today,
                  completed: widget.progress.isCompletedOn(day),
                  frozen: widget.progress.isFrozenOn(day),
                );
              },
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _Legend(
                    icon: Icons.local_fire_department_rounded,
                    text: 'Gespielt'),
                _Legend(icon: Icons.ac_unit_rounded, text: 'Auf Eis'),
                _Legend(icon: Icons.remove_circle_outline, text: 'Verpasst'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FreezeBadge extends StatelessWidget {
  const _FreezeBadge({required this.progress});
  final PlayerProgress progress;

  @override
  Widget build(BuildContext context) {
    final available = progress.streakFreezeAvailable;
    return Tooltip(
      message: available
          ? 'Ein Eiszapfen schützt automatisch einen verpassten Tag.'
          : '${progress.streakFreezeRefillDays} von 10 aktiven Tagen bis zum neuen Eiszapfen.',
      child: Chip(
        avatar: const Icon(Icons.ac_unit_rounded, size: 18),
        label:
            Text(available ? '1/1' : '${progress.streakFreezeRefillDays}/10'),
      ),
    );
  }
}

class _StreakDay extends StatelessWidget {
  const _StreakDay({
    required this.day,
    required this.today,
    required this.completed,
    required this.frozen,
  });

  final DateTime day;
  final DateTime today;
  final bool completed;
  final bool frozen;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final future = day.isAfter(today);
    final isToday = day.isAtSameMomentAs(today);
    final missed = !future && !completed && !frozen && !isToday;
    final icon = completed
        ? Icons.local_fire_department_rounded
        : frozen
            ? Icons.ac_unit_rounded
            : missed
                ? Icons.remove_circle_outline
                : null;
    final description = completed
        ? 'Rätsel gelöst'
        : frozen
            ? 'Durch Eiszapfen geschützt'
            : missed
                ? 'Kein Rätsel abgeschlossen'
                : isToday
                    ? 'Heute'
                    : 'Zukünftiger Tag';
    return Semantics(
      label: '${day.day}. ${_monthName(day.month)}: $description',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('${day.day}. ${_monthName(day.month)}: $description')),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: completed
                ? colors.primaryContainer
                : frozen
                    ? colors.tertiaryContainer
                    : null,
            border:
                isToday ? Border.all(color: colors.primary, width: 2) : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${day.day}', style: const TextStyle(fontSize: 11)),
              if (icon != null)
                Icon(icon,
                    size: 17,
                    color: missed ? colors.outline : colors.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 17), const SizedBox(width: 4), Text(text)],
      );
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);
DateTime _monthOnly(DateTime value) => DateTime(value.year, value.month);

String _monthName(int month) => const [
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
      'Dezember',
    ][month - 1];
