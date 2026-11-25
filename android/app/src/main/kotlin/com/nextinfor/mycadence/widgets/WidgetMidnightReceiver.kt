package com.nextinfor.mycadence.widgets

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class WidgetMidnightReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        WidgetStore.notifyAllWidgets(context)
    }
}
