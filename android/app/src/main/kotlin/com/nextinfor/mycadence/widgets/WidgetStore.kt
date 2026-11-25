package com.nextinfor.mycadence.widgets

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import com.nextinfor.mycadence.MainActivity
import com.nextinfor.mycadence.R
import org.json.JSONObject
import java.util.Calendar

data class WidgetTaskItem(
    val id: String,
    val title: String,
    val timeLabel: String?,
    val colorArgb: Int,
    val overdue: Boolean,
    val done: Boolean,
)

data class WidgetColors(
    val surface: Int,
    val text: Int,
    val muted: Int,
    val danger: Int,
    val accent: Int,
    val onAccent: Int,
)

data class TodayWidgetData(
    val title: String,
    val dateLabel: String,
    val emptyLabel: String,
    val overdueLabel: String,
    val overdueCount: Int,
    val todayCount: Int,
    val items: List<WidgetTaskItem>,
    val colors: WidgetColors,
)

object WidgetStore {
    private const val PREFS_NAME = "cadence_home_widgets"
    private const val KEY_SNAPSHOT = "snapshot_json"
    const val EXTRA_WIDGET_URI = "cadence_widget_uri"
    private const val MIDNIGHT_REQUEST_CODE = 71501

    fun saveSnapshot(context: Context, json: String) {
        context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_SNAPSHOT, json)
            .apply()
        notifyAllWidgets(context)
    }

    fun readRawSnapshot(context: Context): String? =
        context
            .getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_SNAPSHOT, null)

    fun readTodayData(context: Context): TodayWidgetData {
        val raw = readRawSnapshot(context)
        if (raw.isNullOrBlank()) {
            val colors = resolveColors(
                context = context,
                themeMode = "system",
                lightsOut = false,
                accentArgb = 0xFF1D9BF0.toInt(),
            )
            return TodayWidgetData(
                title = context.getString(R.string.widget_today_label),
                dateLabel = "",
                emptyLabel = context.getString(R.string.widget_today_empty),
                overdueLabel = "",
                overdueCount = 0,
                todayCount = 0,
                items = emptyList(),
                colors = colors,
            )
        }
        return try {
            val root = JSONObject(raw)
            val colors = resolveColors(
                context = context,
                themeMode = root.optString("themeMode", "system"),
                lightsOut = root.optBoolean("lightsOut", false),
                accentArgb = root.optLong("accentArgb", 0xFF1D9BF0L).toInt(),
            )
            val arr = root.optJSONArray("todayItems")
            val items = mutableListOf<WidgetTaskItem>()
            if (arr != null) {
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    items.add(
                        WidgetTaskItem(
                            id = o.optString("id"),
                            title = o.optString("title"),
                            timeLabel = if (o.has("timeLabel") && !o.isNull("timeLabel")) {
                                o.optString("timeLabel")
                            } else {
                                null
                            },
                            colorArgb = o.optLong("colorArgb", 0xFF3B82F6L).toInt(),
                            overdue = o.optBoolean("overdue", false),
                            done = o.optBoolean("done", false),
                        ),
                    )
                }
            }
            TodayWidgetData(
                title = root.optString("todayTitle", context.getString(R.string.widget_today_label)),
                dateLabel = root.optString("todayDateLabel", ""),
                emptyLabel = root.optString(
                    "emptyTodayLabel",
                    context.getString(R.string.widget_today_empty),
                ),
                overdueLabel = root.optString("overdueLabel", ""),
                overdueCount = root.optInt("overdueCount", 0),
                todayCount = root.optInt("todayCount", 0),
                items = items,
                colors = colors,
            )
        } catch (_: Exception) {
            val colors = resolveColors(
                context = context,
                themeMode = "system",
                lightsOut = false,
                accentArgb = 0xFF1D9BF0.toInt(),
            )
            TodayWidgetData(
                title = context.getString(R.string.widget_today_label),
                dateLabel = "",
                emptyLabel = context.getString(R.string.widget_today_empty),
                overdueLabel = "",
                overdueCount = 0,
                todayCount = 0,
                items = emptyList(),
                colors = colors,
            )
        }
    }

    fun resolveColors(
        context: Context,
        themeMode: String,
        lightsOut: Boolean,
        accentArgb: Int,
    ): WidgetColors {
        val systemDark = (
            context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK
        ) == Configuration.UI_MODE_NIGHT_YES
        val dark = when (themeMode) {
            "light" -> false
            "dark" -> true
            else -> systemDark
        }
        val r = Color.red(accentArgb)
        val g = Color.green(accentArgb)
        val b = Color.blue(accentArgb)
        val luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255.0
        val onAccent = if (luminance > 0.62) Color.parseColor("#111827") else Color.WHITE

        return when {
            !dark -> WidgetColors(
                surface = Color.parseColor("#FFFFFF"),
                text = Color.parseColor("#111827"),
                muted = Color.parseColor("#6B7280"),
                danger = Color.parseColor("#DC2626"),
                accent = accentArgb,
                onAccent = onAccent,
            )
            lightsOut -> WidgetColors(
                surface = Color.parseColor("#000000"),
                text = Color.parseColor("#FFFFFF"),
                muted = Color.parseColor("#A1A1AA"),
                danger = Color.parseColor("#F87171"),
                accent = accentArgb,
                onAccent = onAccent,
            )
            else -> WidgetColors(
                surface = Color.parseColor("#121214"),
                text = Color.parseColor("#F3F4F6"),
                muted = Color.parseColor("#9CA3AF"),
                danger = Color.parseColor("#F87171"),
                accent = accentArgb,
                onAccent = onAccent,
            )
        }
    }

    fun launchIntent(context: Context, uri: String): Intent =
        Intent(context, MainActivity::class.java).apply {
            action = Intent.ACTION_VIEW
            putExtra(EXTRA_WIDGET_URI, uri)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                Intent.FLAG_ACTIVITY_CLEAR_TOP or
                Intent.FLAG_ACTIVITY_SINGLE_TOP
        }

    fun notifyAllWidgets(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        val todayIds = manager.getAppWidgetIds(
            ComponentName(context, TodayWidgetProvider::class.java),
        )
        if (todayIds.isNotEmpty()) {
            TodayWidgetProvider.updateWidgets(context, manager, todayIds)
            manager.notifyAppWidgetViewDataChanged(todayIds, R.id.widget_today_list)
            scheduleMidnightRefresh(context)
        }
    }

    fun scheduleMidnightRefresh(context: Context) {
        val am = context.getSystemService(Context.ALARM_SERVICE) as? AlarmManager ?: return
        val cal = Calendar.getInstance().apply {
            add(Calendar.DAY_OF_YEAR, 1)
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 1)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val pi = PendingIntent.getBroadcast(
            context,
            MIDNIGHT_REQUEST_CODE,
            Intent(context, WidgetMidnightReceiver::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        am.set(AlarmManager.RTC, cal.timeInMillis, pi)
    }
}
