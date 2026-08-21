import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_logic_prototype/core/presentation/streak_calendar.dart';
import 'package:project_logic_prototype/game_storage.dart';

void main() {
  testWidgets('calendar explains played frozen and missed days',
      (tester) async {
    final now = DateTime.now();
    String key(DateTime day) =>
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final completedDay = now.subtract(const Duration(days: 2));
    final frozenDay = now.subtract(const Duration(days: 1));
    final progress = PlayerProgress(
      totalCompleted: 1,
      totalPlaySeconds: 30,
      completedDays: [key(completedDay)],
      frozenDays: [key(frozenDay)],
      streakFreezeAvailable: false,
      streakFreezeRefillDays: 4,
      streakProtectionStartedOn: key(completedDay),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StreakCalendarCard(progress: progress),
        ),
      ),
    ));

    expect(find.text('4 von 10 aktiv'), findsOneWidget);
    expect(find.text('Dein Eiszapfen hat gestern deine Spielserie gerettet.'),
        findsOneWidget);
    expect(find.text('Gespielt'), findsOneWidget);
    expect(find.text('Auf Eis'), findsOneWidget);
    expect(find.text('Verpasst'), findsOneWidget);
    expect(find.byIcon(Icons.ac_unit_rounded), findsWidgets);
    expect(find.byIcon(Icons.local_fire_department_rounded), findsWidgets);
  });

  testWidgets('calendar announces a refilled streak freeze', (tester) async {
    final now = DateTime.now();
    String key(DateTime day) =>
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final progress = PlayerProgress(
      totalCompleted: 10,
      totalPlaySeconds: 300,
      completedDays: [key(now)],
      streakFreezeAvailable: true,
      lastFreezeRefilledOn: key(now),
    );

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StreakCalendarCard(progress: progress),
        ),
      ),
    ));

    expect(find.text('1 von 1 verfügbar'), findsOneWidget);
    expect(
      find.text(
          '10 von 10 aktiven Tagen geschafft: Dein Eiszapfen ist wieder aufgefüllt.'),
      findsOneWidget,
    );
  });
}
