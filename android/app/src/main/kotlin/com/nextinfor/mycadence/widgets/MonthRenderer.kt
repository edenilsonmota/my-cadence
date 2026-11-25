package com.nextinfor.mycadence.widgets

import android.app.PendingIntent
import android.content.Context
import android.graphics.Color
import android.view.View
import android.widget.RemoteViews
import com.nextinfor.mycadence.R

/** Monta o cabeçalho e a grade mensal nos layouts `widget_month` e `widget_hybrid`. */
object MonthRenderer {
    private val dotIds = intArrayOf(
        R.id.month_cell_dot1,
        R.id.month_cell_dot2,
        R.id.month_cell_dot3,
    )

    fun render(
        context: Context,
        views: RemoteViews,
        appWidgetId: Int,
        requestBase: Int,
        month: MonthWidgetData,
        colors: WidgetColors,
        chips: Boolean = false,
    ) {
        val pkg = context.packageName
        views.setInt(R.id.widget_cal_bg, "setColorFilter", colors.surface)
        views.setTextViewText(R.id.widget_cal_title, month.title)
        views.setTextColor(R.id.widget_cal_title, colors.text)
        views.setInt(R.id.widget_cal_add_bg, "setColorFilter", colors.accent)
        views.setInt(R.id.widget_cal_add_icon, "setColorFilter", colors.onAccent)

        // Cabeçalho abre a Agenda (no mês); + cria tarefa para hoje.
        views.setOnClickPendingIntent(
            R.id.widget_cal_header,
            activityPi(context, requestBase + 1, "cadence://agenda"),
        )
        views.setOnClickPendingIntent(
            R.id.widget_cal_add_btn,
            activityPi(context, requestBase + 2, "cadence://new-task?dueToday=1"),
        )

        views.removeAllViews(R.id.widget_cal_weekdays)
        for (label in month.weekdays) {
            val wd = RemoteViews(pkg, R.layout.widget_month_weekday)
            wd.setTextViewText(R.id.month_weekday, label)
            wd.setTextColor(R.id.month_weekday, colors.muted)
            views.addView(R.id.widget_cal_weekdays, wd)
        }

        views.removeAllViews(R.id.widget_cal_grid)
        val faded = withAlpha(colors.muted, 0.55f)
        for (week in month.days.chunked(7)) {
            val row = RemoteViews(pkg, R.layout.widget_month_row)
            for (day in week) {
                val index = month.days.indexOf(day)
                val cell = RemoteViews(pkg, R.layout.widget_month_cell)
                cell.setTextViewText(R.id.month_cell_day, day.day.toString())
                cell.setTextColor(
                    R.id.month_cell_day,
                    when {
                        day.today -> colors.onAccent
                        day.inMonth -> colors.text
                        else -> faded
                    },
                )
                if (day.today) {
                    cell.setViewVisibility(R.id.month_cell_today, View.VISIBLE)
                    cell.setInt(R.id.month_cell_today, "setColorFilter", colors.accent)
                }
                if (chips) {
                    // Grade com linhas e chips com o título (estilo agenda).
                    cell.setViewVisibility(R.id.month_cell_line, View.VISIBLE)
                    cell.setInt(R.id.month_cell_line, "setBackgroundColor", withAlpha(colors.muted, 0.25f))
                    cell.setViewVisibility(R.id.month_cell_dots, View.GONE)
                    cell.setViewVisibility(R.id.month_cell_chips, View.VISIBLE)
                    cell.removeAllViews(R.id.month_cell_chips)
                    day.colors.forEachIndexed { i, color ->
                        val chip = RemoteViews(pkg, R.layout.widget_month_chip)
                        chip.setInt(
                            R.id.month_chip_bg,
                            "setColorFilter",
                            if (day.inMonth) color else withAlpha(color, 0.45f),
                        )
                        chip.setTextViewText(R.id.month_chip_text, day.titles.getOrNull(i) ?: "")
                        cell.addView(R.id.month_cell_chips, chip)
                    }
                    if (day.more > 0) {
                        cell.setViewVisibility(R.id.month_cell_more, View.VISIBLE)
                        cell.setTextViewText(R.id.month_cell_more, "+${day.more}")
                        cell.setTextColor(R.id.month_cell_more, colors.muted)
                    }
                } else dotIds.forEachIndexed { i, id ->
                    val color = day.colors.getOrNull(i)
                    if (color != null) {
                        cell.setViewVisibility(id, View.VISIBLE)
                        cell.setInt(
                            id,
                            "setColorFilter",
                            if (day.inMonth) color else withAlpha(color, 0.45f),
                        )
                    }
                }
                cell.setOnClickPendingIntent(
                    R.id.month_cell_root,
                    activityPi(
                        context,
                        requestBase + 10 + index,
                        "cadence://agenda?date=${day.iso}",
                    ),
                )
                row.addView(R.id.month_row, cell)
            }
            views.addView(R.id.widget_cal_grid, row)
        }
    }

    /** Código de requisição único por widget (cada célula tem o seu). */
    fun requestBase(kind: Int, appWidgetId: Int): Int = kind * 1_000_000 + (appWidgetId % 10_000) * 64

    private fun activityPi(context: Context, code: Int, uri: String): PendingIntent =
        PendingIntent.getActivity(
            context,
            code,
            WidgetStore.launchIntent(context, uri),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

    private fun withAlpha(color: Int, alpha: Float): Int =
        Color.argb((alpha * 255).toInt(), Color.red(color), Color.green(color), Color.blue(color))
}
