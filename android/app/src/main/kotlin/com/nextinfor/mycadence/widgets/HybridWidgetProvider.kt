package com.nextinfor.mycadence.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import com.nextinfor.mycadence.MainActivity
import com.nextinfor.mycadence.R

/** Widget "Mês + Hoje": calendário do mês em cima e a lista de hoje embaixo. */
class HybridWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
        WidgetStore.scheduleMidnightRefresh(context)
    }

    companion object {
        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            val today = WidgetStore.readTodayData(context)
            val month = WidgetStore.readMonthData(context)
            val c = today.colors
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget_hybrid)
                val base = MonthRenderer.requestBase(3, appWidgetId)
                MonthRenderer.render(context, views, appWidgetId, base, month, c)

                views.setInt(R.id.widget_hybrid_divider, "setColorFilter", c.muted)
                val total = today.overdueCount + today.todayCount
                val label = listOf(today.title, today.dateLabel, if (total > 0) "$total" else "")
                    .filter { it.isNotBlank() }
                    .joinToString(" · ")
                views.setTextViewText(R.id.widget_hybrid_label, label)
                views.setTextColor(
                    R.id.widget_hybrid_label,
                    if (today.overdueCount > 0) c.danger else c.text,
                )
                views.setOnClickPendingIntent(
                    R.id.widget_hybrid_label,
                    PendingIntent.getActivity(
                        context,
                        base + 3,
                        WidgetStore.launchIntent(context, "cadence://today"),
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                    ),
                )
                views.setTextViewText(R.id.widget_hybrid_empty, today.emptyLabel)
                views.setTextColor(R.id.widget_hybrid_empty, c.muted)

                // Mesma lista rolável do widget "Hoje".
                val serviceIntent = Intent(context, TodayWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    setData(Uri.parse(toUri(Intent.URI_INTENT_SCHEME)))
                }
                @Suppress("DEPRECATION")
                views.setRemoteAdapter(R.id.widget_hybrid_list, serviceIntent)
                views.setEmptyView(R.id.widget_hybrid_list, R.id.widget_hybrid_empty)
                views.setViewVisibility(R.id.widget_hybrid_empty, View.GONE)

                val templateIntent = Intent(context, MainActivity::class.java).apply {
                    action = Intent.ACTION_VIEW
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                }
                val mutableFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    PendingIntent.FLAG_MUTABLE
                } else {
                    0
                }
                views.setPendingIntentTemplate(
                    R.id.widget_hybrid_list,
                    PendingIntent.getActivity(
                        context,
                        base + 4,
                        templateIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag,
                    ),
                )
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
}
