package com.example.project_logic_prototype

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import java.util.Calendar

object ReminderScheduler {
    private const val preferencesName = "project_logic_reminders"
    const val dailyAction = "project_logic.DAILY_REMINDER"
    const val streakAction = "project_logic.STREAK_WARNING"

    fun configure(
        context: Context,
        dailyEnabled: Boolean,
        dailyMinutes: Int,
        streakEnabled: Boolean,
        streakMinutes: Int,
    ) {
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE).edit()
            .putBoolean("dailyEnabled", dailyEnabled)
            .putInt("dailyMinutes", dailyMinutes)
            .putBoolean("streakEnabled", streakEnabled)
            .putInt("streakMinutes", streakMinutes)
            .apply()
        schedule(context, dailyAction, 4101, dailyEnabled, dailyMinutes)
        schedule(context, streakAction, 4102, streakEnabled, streakMinutes)
    }

    fun restore(context: Context) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        configure(
            context,
            preferences.getBoolean("dailyEnabled", false),
            preferences.getInt("dailyMinutes", 18 * 60),
            preferences.getBoolean("streakEnabled", false),
            preferences.getInt("streakMinutes", 21 * 60),
        )
    }

    fun preferences(context: Context) =
        context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)

    private fun schedule(
        context: Context,
        action: String,
        requestCode: Int,
        enabled: Boolean,
        minutes: Int,
    ) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val intent = Intent(context, ReminderReceiver::class.java).setAction(action)
        val pending = PendingIntent.getBroadcast(
            context,
            requestCode,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        alarmManager.cancel(pending)
        if (!enabled) return
        val first = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, minutes.coerceIn(0, 1439) / 60)
            set(Calendar.MINUTE, minutes.coerceIn(0, 1439) % 60)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
            if (timeInMillis <= System.currentTimeMillis()) add(Calendar.DAY_OF_YEAR, 1)
        }
        alarmManager.setInexactRepeating(
            AlarmManager.RTC_WAKEUP,
            first.timeInMillis,
            AlarmManager.INTERVAL_DAY,
            pending,
        )
    }
}
