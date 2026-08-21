import 'package:flutter/material.dart';

import '../../app_localizations.dart';
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
    final strings = context.strings;
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
                        strings.plural(
                          widget.progress.currentStreak,
                          '1 Tag Spielserie',
                          '${widget.progress.currentStreak} Tage Spielserie',
                          '1 day streak',
                          '${widget.progress.currentStreak} day streak',
                        ),
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(strings.text(
                        'Beste Serie: ${widget.progress.bestStreak} Tage',
                        'Best streak: ${widget.progress.bestStreak} days',
                      )),
                    ],
                  ),
                ),
                _FreezeBadge(progress: widget.progress),
              ],
            ),
            if (widget.progress.wasProtectedYesterdayAt(DateTime.now())) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.tertiaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.ac_unit_rounded,
                        color: colors.onTertiaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.text(
                          'Dein Eiszapfen hat gestern deine Spielserie gerettet.',
                          'Your streak freeze saved your streak yesterday.',
                        ),
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (widget.progress.wasFreezeRefilledTodayAt(DateTime.now())) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Icon(Icons.ac_unit_rounded,
                        color: colors.onPrimaryContainer),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        strings.text(
                          '10 von 10 aktiven Tagen geschafft: Dein Eiszapfen ist wieder aufgefüllt.',
                          '10 of 10 active days complete: your streak freeze has been refilled.',
                        ),
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                IconButton(
                  tooltip: strings.text('Vorheriger Monat', 'Previous month'),
                  onPressed: () => setState(
                      () => _month = DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Expanded(
                  child: Text(
                    MaterialLocalizations.of(context).formatMonthYear(_month),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: strings.text('Nächster Monat', 'Next month'),
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
                for (final label in strings.isEnglish
                    ? ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                    : ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'])
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
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _Legend(
                    icon: Icons.local_fire_department_rounded,
                    text: strings.text('Gespielt', 'Played')),
                _Legend(
                    icon: Icons.ac_unit_rounded,
                    text: strings.text('Auf Eis', 'Frozen')),
                _Legend(
                    icon: Icons.remove_circle_outline,
                    text: strings.text('Verpasst', 'Missed')),
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
    final strings = context.strings;
    return Tooltip(
      message: available
          ? strings.text(
              'Ein Eiszapfen schützt automatisch einen verpassten Tag.',
              'One streak freeze automatically protects a missed day.',
            )
          : strings.text(
              'Noch ${progress.streakFreezeRefillDaysRemaining} aktive Tage bis zum neuen Eiszapfen.',
              '${progress.streakFreezeRefillDaysRemaining} active days until a new streak freeze.',
            ),
      child: Chip(
        avatar: const Icon(Icons.ac_unit_rounded, size: 18),
        label: Text(available
            ? strings.text('1 von 1 verfügbar', '1 of 1 available')
            : strings.text('${progress.streakFreezeRefillDays} von 10 aktiv',
                '${progress.streakFreezeRefillDays} of 10 active')),
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
    final strings = context.strings;
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
        ? strings.text('Rätsel gelöst', 'Puzzle solved')
        : frozen
            ? strings.text(
                'Durch Eiszapfen geschützt', 'Protected by a streak freeze')
            : missed
                ? strings.text(
                    'Kein Rätsel abgeschlossen', 'No puzzle completed')
                : isToday
                    ? strings.text('Heute', 'Today')
                    : strings.text('Zukünftiger Tag', 'Future day');
    final date = MaterialLocalizations.of(context).formatMediumDate(day);
    return Semantics(
      label: '$date: $description',
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$date: $description')),
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
