String missionEventTitle(String id) {
  if (id.endsWith('-daily-complete')) return 'Alle Tagesziele geschafft';
  if (id.endsWith('-weekly-complete')) return 'Alle Wochenziele geschafft';
  if (id.endsWith('-challenge')) return 'Heute dran';
  if (id.endsWith('-generator')) return 'Neue Herausforderung';
  if (id.endsWith('-catalog')) return 'Aus der Sammlung';
  if (id.endsWith('-active-days')) return 'Dreimal Zeit zum Denken';
  if (id.endsWith('-five-puzzles')) return 'Fünf klare Momente';
  if (id.endsWith('-hard')) return 'Schwere Kost';
  if (id.endsWith('-no-hint')) {
    return id.startsWith('daily-') ? 'Ganz ohne Hilfe' : 'Aus eigener Kraft';
  }
  if (id.endsWith('-variety')) {
    return id.startsWith('daily-')
        ? 'Doppelte Abwechslung'
        : 'Abwechslungsreiche Woche';
  }
  return 'Mission geschafft';
}

String missionEventDetail(String id) {
  if (id.endsWith('-daily-complete')) return 'Tages-Komplettbonus';
  if (id.endsWith('-weekly-complete')) return 'Wochen-Komplettbonus';
  if (id.startsWith('daily-')) return 'Tagesziel';
  if (id.startsWith('week-')) return 'Wochenziel';
  return 'Missionsbelohnung';
}
