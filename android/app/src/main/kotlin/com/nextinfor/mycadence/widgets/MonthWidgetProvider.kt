package com.nextinfor.mycadence.widgets

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.nextinfor.mycadence.R

/**
 * Widget "Mês": calendário com os títulos das tarefas de cada dia e ‹ › para
 * ver os meses vizinhos que vieram no snapshot (o deslocamento fica salvo por
 * widget).
 */
class MonthWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        updateWidgets(context, appWidgetManager, appWidgetIds)
        WidgetStore.scheduleMidnightRefresh(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        val step = when (intent.action) {
            ACTION_PREV -> -1
            ACTION_NEXT -> 1
            else -> 0
        }
        if (step == 0) {
            super.onReceive(context, intent)
            return
        }
        val id = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        if (id == -1) return
        val next = WidgetStore.monthOffset(context, id) + step
        if (next in WidgetStore.availableMonthOffsets(context)) {
            WidgetStore.setMonthOffset(context, id, next)
            updateWidgets(context, AppWidgetManager.getInstance(context), intArrayOf(id))
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        for (id in appWidgetIds) WidgetStore.setMonthOffset(context, id, 0)
    }

    companion object {
        private const val ACTION_PREV = "com.nextinfor.mycadence.widgets.MONTH_PREV"
        private const val ACTION_NEXT = "com.nextinfor.mycadence.widgets.MONTH_NEXT"

        fun updateWidgets(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray,
        ) {
            val colors = WidgetStore.readTodayData(context).colors
            val available = WidgetStore.availableMonthOffsets(context)
            for (appWidgetId in appWidgetIds) {
                var offset = WidgetStore.monthOffset(context, appWidgetId)
                if (offset !in available) {
                    offset = 0
                    WidgetStore.setMonthOffset(context, appWidgetId, 0)
                }
                val month = WidgetStore.readMonthData(context, offset)
                val views = RemoteViews(context.packageName, R.layout.widget_month)
                val base = MonthRenderer.requestBase(2, appWidgetId)
                MonthRenderer.render(
                    context,
                    views,
                    appWidgetId,
                    base,
                    month,
                    colors,
                    chips = true,
                )
                views.setInt(R.id.widget_cal_prev, "setColorFilter", colors.muted)
                views.setInt(R.id.widget_cal_next, "setColorFilter", colors.muted)
                views.setOnClickPendingIntent(
                    R.id.widget_cal_prev,
                    stepIntent(context, appWidgetId, ACTION_PREV, base + 3),
                )
                views.setOnClickPendingIntent(
                    R.id.widget_cal_next,
                    stepIntent(context, appWidgetId, ACTION_NEXT, base + 4),
                )
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }

        private fun stepIntent(
            context: Context,
            appWidgetId: Int,
            action: String,
            code: Int,
        ): PendingIntent = PendingIntent.getBroadcast(
            context,
            code,
            Intent(context, MonthWidgetProvider::class.java).apply {
                this.action = action
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
    }
}
