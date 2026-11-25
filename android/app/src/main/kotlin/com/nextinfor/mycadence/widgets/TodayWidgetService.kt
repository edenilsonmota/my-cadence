package com.nextinfor.mycadence.widgets

import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import com.nextinfor.mycadence.R

class TodayWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodayWidgetFactory(applicationContext)
}

private class TodayWidgetFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {
    private var data: TodayWidgetData = WidgetStore.readTodayData(context)

    override fun onCreate() {
        data = WidgetStore.readTodayData(context)
    }

    override fun onDataSetChanged() {
        data = WidgetStore.readTodayData(context)
    }

    override fun onDestroy() = Unit

    override fun getCount(): Int = data.items.size

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_today_item)
        if (position !in data.items.indices) return views
        val item = data.items[position]
        val c = data.colors

        views.setInt(
            R.id.widget_today_item_bar,
            "setColorFilter",
            if (item.overdue) c.danger else item.colorArgb,
        )
        views.setTextViewText(R.id.widget_today_item_title, item.title)
        views.setTextColor(R.id.widget_today_item_title, c.text)

        if (!item.timeLabel.isNullOrBlank()) {
            views.setTextViewText(R.id.widget_today_item_time, item.timeLabel)
            views.setTextColor(
                R.id.widget_today_item_time,
                if (item.overdue) c.danger else c.muted,
            )
            views.setViewVisibility(R.id.widget_today_item_time, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_today_item_time, View.GONE)
        }

        val fillIn = Intent().apply {
            putExtra(WidgetStore.EXTRA_WIDGET_URI, "cadence://task/${item.id}")
        }
        views.setOnClickFillInIntent(R.id.widget_today_item_root, fillIn)

        views.setInt(R.id.widget_today_item_check, "setColorFilter", c.muted)
        val complete = Intent().apply {
            putExtra(WidgetStore.EXTRA_WIDGET_URI, "cadence://complete/${item.id}")
        }
        views.setOnClickFillInIntent(R.id.widget_today_item_check, complete)
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long =
        data.items.getOrNull(position)?.id?.hashCode()?.toLong() ?: position.toLong()

    override fun hasStableIds(): Boolean = true
}
