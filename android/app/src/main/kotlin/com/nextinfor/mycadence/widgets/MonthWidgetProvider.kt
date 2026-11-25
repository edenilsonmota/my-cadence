package com.nextinfor.mycadence.widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import com.nextinfor.mycadence.R

/** Widget "Mês": calendário do mês atual com pontinhos das tarefas de cada dia. */
class MonthWidgetProvider : AppWidgetProvider() {
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
            val colors = WidgetStore.readTodayData(context).colors
            val month = WidgetStore.readMonthData(context)
            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget_month)
                MonthRenderer.render(
                    context,
                    views,
                    appWidgetId,
                    MonthRenderer.requestBase(2, appWidgetId),
                    month,
                    colors,
                )
                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
}
