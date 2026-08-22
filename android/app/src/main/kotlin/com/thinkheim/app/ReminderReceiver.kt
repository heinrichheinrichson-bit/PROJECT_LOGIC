package com.thinkheim.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale
import kotlin.math.abs

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED ||
            intent.action == Intent.ACTION_TIME_CHANGED ||
            intent.action == Intent.ACTION_TIMEZONE_CHANGED ||
            intent.action == Intent.ACTION_MY_PACKAGE_REPLACED
        ) {
            ReminderScheduler.restore(context)
            return
        }
        // Always plan tomorrow first. Even when today's notification is
        // suppressed because the player has already solved a puzzle, the
        // reminder chain must continue.
        intent.action?.let { ReminderScheduler.scheduleNext(context, it) }
        val state = progressState(context)
        if (state.completedToday) return
        val settings = ReminderScheduler.preferences(context)
        val isStreak = intent.action == ReminderScheduler.streakAction
        if (isStreak && state.currentStreak == 0) return
        if (!isStreak && shouldPreferStreak(settings, state.currentStreak)) return
        show(context, isStreak, state)
    }

    private fun shouldPreferStreak(
        settings: android.content.SharedPreferences,
        currentStreak: Int,
    ): Boolean = settings.getBoolean("streakEnabled", false) &&
        currentStreak > 0 &&
        abs(settings.getInt("dailyMinutes", 1080) -
            settings.getInt("streakMinutes", 1260)) <= 60

    private fun show(context: Context, streak: Boolean, state: ProgressState) {
        if (Build.VERSION.SDK_INT >= 33 &&
            context.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) !=
            PackageManager.PERMISSION_GRANTED
        ) return
        val manager = context.getSystemService(NotificationManager::class.java)
        val channelId = "project_logic_reminders"
        val english = usesEnglish(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(NotificationChannel(
                channelId,
                if (english) "Play reminders" else "Spielerinnerungen",
                NotificationManager.IMPORTANCE_DEFAULT,
            ).apply {
                description = if (english) {
                    "Daily reminders and streak warnings"
                } else {
                    "Tägliche Erinnerungen und Streak-Warnungen"
                }
            })
        }
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pending = PendingIntent.getActivity(
            context, 4200, launch, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val title: String
        val text: String
        if (streak) {
            title = if (english) {
                "Your ${state.currentStreak}-day streak is still at risk"
            } else {
                "Deine ${state.currentStreak}-Tage-Serie ist noch offen"
            }
            text = if (state.freezeAvailable) {
                if (english) {
                    "Solve a puzzle today. Your streak freeze can protect you if needed."
                } else {
                    "Löse heute noch ein Rätsel. Dein Eiszapfen würde dich notfalls schützen."
                }
            } else {
                if (english) {
                    "Solve a puzzle today to keep your streak going."
                } else {
                    "Löse heute noch ein Rätsel, damit deine Serie weiterläuft."
                }
            }
        } else {
            title = if (english) {
                "Time for a quick logic break"
            } else {
                "Zeit für eine kleine Logikrunde"
            }
            text = if (english) {
                "One puzzle is enough to secure today's play day."
            } else {
                "Ein Rätsel genügt, um deinen heutigen Spieltag zu sichern."
            }
        }
        manager.notify(
            if (streak) 4302 else 4301,
            Notification.Builder(context, channelId)
                .setSmallIcon(android.R.drawable.ic_dialog_info)
                .setContentTitle(title)
                .setContentText(text)
                .setStyle(Notification.BigTextStyle().bigText(text))
                .setContentIntent(pending)
                .setAutoCancel(true)
                .setOnlyAlertOnce(true)
                .build(),
        )
    }

    private fun usesEnglish(context: Context): Boolean {
        val flutter = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        return when (flutter.getString("flutter.setting_language_v1", "german")) {
            "english" -> true
            "system" -> Locale.getDefault().language == "en"
            else -> false
        }
    }

    private fun progressState(context: Context): ProgressState {
        val flutter = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val raw = flutter.getString("flutter.player_progress_v1", null)
            ?: return ProgressState(false, 0, true)
        return try {
            val json = JSONObject(raw)
            val formatter = SimpleDateFormat("yyyy-MM-dd", Locale.ROOT)
            val today = Calendar.getInstance().apply { zeroTime() }
            val todayKey = formatter.format(today.time)
            val days = mutableSetOf<String>()
            json.optJSONArray("completedDays")?.let { array ->
                for (index in 0 until array.length()) days.add(array.optString(index))
            }
            val completedToday = days.contains(todayKey)
            json.optJSONArray("frozenDays")?.let { array ->
                for (index in 0 until array.length()) days.add(array.optString(index))
            }
            ProgressState(
                completedToday,
                currentStreak(days, today, formatter),
                json.optBoolean("streakFreezeAvailable", true),
            )
        } catch (_: Exception) {
            ProgressState(false, 0, true)
        }
    }

    private fun currentStreak(
        days: Set<String>,
        today: Calendar,
        formatter: SimpleDateFormat,
    ): Int {
        var cursor = (today.clone() as Calendar)
        if (!days.contains(formatter.format(cursor.time))) {
            cursor.add(Calendar.DAY_OF_YEAR, -1)
        }
        var streak = 0
        while (days.contains(formatter.format(cursor.time))) {
            streak++
            cursor.add(Calendar.DAY_OF_YEAR, -1)
        }
        return streak
    }

    private fun Calendar.zeroTime() {
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }

    private data class ProgressState(
        val completedToday: Boolean,
        val currentStreak: Int,
        val freezeAvailable: Boolean,
    )
}
