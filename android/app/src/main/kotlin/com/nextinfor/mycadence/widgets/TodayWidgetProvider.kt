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

class TodayWidgetProvider : AppWidgetProvider() {
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
            val data = WidgetStore.readTodayData(context)
            val c = data.colors

            for (appWidgetId in appWidgetIds) {
                val views = RemoteViews(context.packageName, R.layout.widget_today)

                // Cores do tema e destaque.
                views.setInt(R.id.widget_today_bg, "setColorFilter", c.surface)
                views.setTextViewText(R.id.widget_today_title, data.title)
                views.setTextColor(R.id.widget_today_title, c.text)

                val subtitleParts = mutableListOf<String>()
                if (data.dateLabel.isNotBlank()) subtitleParts.add(data.dateLabel)
                val total = data.overdueCount + data.todayCount
                if (total > 0) subtitleParts.add("$total")
                val subtitle = subtitleParts.joinToString(" · ")
                views.setTextViewText(R.id.widget_today_subtitle, subtitle)
                views.setTextColor(
                    R.id.widget_today_subtitle,
                    if (data.overdueCount > 0) c.danger else c.muted,
                )
                views.setViewVisibility(
                    R.id.widget_today_subtitle,
                    if (subtitle.isBlank()) View.GONE else View.VISIBLE,
                )

                // Botão + na cor de destaque do app.
                views.setInt(R.id.widget_today_add_bg, "setColorFilter", c.accent)
                views.setInt(R.id.widget_today_add_icon, "setColorFilter", c.onAccent)

                // Texto vazio.
                views.setTextViewText(R.id.widget_today_empty, data.emptyLabel)
                views.setTextColor(R.id.widget_today_empty, c.muted)

                // Cliques do cabeçalho (abre Hoje) e do botão + (nova tarefa hoje).
                val openTodayPi = PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + 1,
                    WidgetStore.launchIntent(context, "cadence://today"),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_today_header, openTodayPi)
                views.setOnClickPendingIntent(R.id.widget_today_empty, openTodayPi)

                val addTaskPi = PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + 2,
                    WidgetStore.launchIntent(context, "cadence://new-task?dueToday=1"),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                views.setOnClickPendingIntent(R.id.widget_today_add_btn, addTaskPi)

                // Lista rolável de tarefas via RemoteViewsService.
                val serviceIntent = Intent(context, TodayWidgetService::class.java).apply {
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                    // Data única garante que o RemoteViewsManager não recicle fábricas
                    // antigas com dados desatualizados.
                    setData(Uri.parse(toUri(Intent.URI_INTENT_SCHEME)))
                }
                @Suppress("DEPRECATION")
                views.setRemoteAdapter(R.id.widget_today_list, serviceIntent)
                views.setEmptyView(R.id.widget_today_list, R.id.widget_today_empty)

                // Template para abrir o hub de cada tarefa clicada na lista.
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
                val templatePi = PendingIntent.getActivity(
                    context,
                    appWidgetId * 10 + 3,
                    templateIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or mutableFlag,
                )
                views.setPendingIntentTemplate(R.id.widget_today_list, templatePi)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            }
        }
    }
}
