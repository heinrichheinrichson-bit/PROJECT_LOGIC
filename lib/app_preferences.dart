import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemePreference {
  system,
  light,
  dark;

  ThemeMode get themeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };

  String get label => switch (this) {
        AppThemePreference.system => 'Systemeinstellung',
        AppThemePreference.light => 'Hell',
        AppThemePreference.dark => 'Dunkel',
      };
}

enum AppLanguagePreference {
  system,
  german,
  english;

  Locale? get locale => switch (this) {
        AppLanguagePreference.system => null,
        AppLanguagePreference.german => const Locale('de'),
        AppLanguagePreference.english => const Locale('en'),
      };
}

class AppPreferences extends ChangeNotifier {
  AppPreferences._({
    required this.themePreference,
    required this.languagePreference,
    required this.animationsEnabled,
    required this.soundsEnabled,
    required this.hapticsEnabled,
    required this.showRuleIssues,
    required this.premiumSimulationEnabled,
    required this.dailyReminderEnabled,
    required this.dailyReminderMinutes,
    required this.streakWarningEnabled,
    required this.streakWarningMinutes,
  });

  static const _themeKey = 'setting_theme_v1';
  static const _languageKey = 'setting_language_v1';
  static const _animationsKey = 'setting_animations_v1';
  static const _soundsKey = 'setting_sounds_v1';
  static const _hapticsKey = 'setting_haptics_v1';
  static const _showRuleIssuesKey = 'setting_rule_issues_v1';
  static const _premiumSimulationKey = 'debug_premium_simulation_v1';
  static const _dailyReminderEnabledKey = 'setting_daily_reminder_v1';
  static const _dailyReminderMinutesKey = 'setting_daily_reminder_minutes_v1';
  static const _streakWarningEnabledKey = 'setting_streak_warning_v1';
  static const _streakWarningMinutesKey = 'setting_streak_warning_minutes_v1';

  AppThemePreference themePreference;
  AppLanguagePreference languagePreference;
  bool animationsEnabled;
  bool soundsEnabled;
  bool hapticsEnabled;
  bool showRuleIssues;
  bool premiumSimulationEnabled;
  bool dailyReminderEnabled;
  int dailyReminderMinutes;
  bool streakWarningEnabled;
  int streakWarningMinutes;

  static Future<AppPreferences> load() async {
    final preferences = await SharedPreferences.getInstance();
    final themeName =
        preferences.getString(_themeKey) ?? AppThemePreference.system.name;
    final theme = AppThemePreference.values.firstWhere(
      (value) => value.name == themeName,
      orElse: () => AppThemePreference.system,
    );
    final languageName = preferences.getString(_languageKey) ??
        AppLanguagePreference.german.name;
    final language = AppLanguagePreference.values.firstWhere(
      (value) => value.name == languageName,
      orElse: () => AppLanguagePreference.german,
    );

    return AppPreferences._(
      themePreference: theme,
      languagePreference: language,
      animationsEnabled: preferences.getBool(_animationsKey) ?? true,
      soundsEnabled: preferences.getBool(_soundsKey) ?? true,
      hapticsEnabled: preferences.getBool(_hapticsKey) ?? true,
      showRuleIssues: preferences.getBool(_showRuleIssuesKey) ?? true,
      premiumSimulationEnabled:
          preferences.getBool(_premiumSimulationKey) ?? false,
      dailyReminderEnabled:
          preferences.getBool(_dailyReminderEnabledKey) ?? false,
      dailyReminderMinutes:
          preferences.getInt(_dailyReminderMinutesKey) ?? 18 * 60,
      streakWarningEnabled:
          preferences.getBool(_streakWarningEnabledKey) ?? false,
      streakWarningMinutes:
          preferences.getInt(_streakWarningMinutesKey) ?? 21 * 60,
    );
  }

  Future<void> setTheme(AppThemePreference value) async {
    if (themePreference == value) return;
    themePreference = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
  }

  Future<void> setLanguage(AppLanguagePreference value) async {
    if (languagePreference == value) return;
    languagePreference = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, value.name);
  }

  Future<void> setAnimationsEnabled(bool value) async {
    if (animationsEnabled == value) return;
    animationsEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_animationsKey, value);
  }

  Future<void> setHapticsEnabled(bool value) async {
    if (hapticsEnabled == value) return;
    hapticsEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hapticsKey, value);
  }

  Future<void> setSoundsEnabled(bool value) async {
    if (soundsEnabled == value) return;
    soundsEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_soundsKey, value);
  }

  Future<void> setShowRuleIssues(bool value) async {
    if (showRuleIssues == value) return;
    showRuleIssues = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_showRuleIssuesKey, value);
  }

  Future<void> setPremiumSimulationEnabled(bool value) async {
    if (premiumSimulationEnabled == value) return;
    premiumSimulationEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_premiumSimulationKey, value);
  }

  Future<void> setDailyReminderEnabled(bool value) async {
    dailyReminderEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_dailyReminderEnabledKey, value);
  }

  Future<void> setDailyReminderMinutes(int value) async {
    dailyReminderMinutes = value.clamp(0, 1439);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_dailyReminderMinutesKey, dailyReminderMinutes);
  }

  Future<void> setStreakWarningEnabled(bool value) async {
    streakWarningEnabled = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_streakWarningEnabledKey, value);
  }

  Future<void> setStreakWarningMinutes(int value) async {
    streakWarningMinutes = value.clamp(0, 1439);
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_streakWarningMinutesKey, streakWarningMinutes);
  }
}

class PreferencesScope extends InheritedNotifier<AppPreferences> {
  const PreferencesScope({
    required AppPreferences preferences,
    required super.child,
    super.key,
  }) : super(notifier: preferences);

  static AppPreferences of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<PreferencesScope>();
    assert(scope != null, 'PreferencesScope is missing.');
    return scope!.notifier!;
  }

  static AppPreferences? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PreferencesScope>()?.notifier;
}
