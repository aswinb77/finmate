package com.example.finmate

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.Calendar

/**
 * DragonWidgetProvider — MOOD SYSTEM REWORK
 *
 * Widget mood is determined by combining:
 *   1. Time of day  (morning / afternoon / evening-night)
 *   2. Spend %      (spent / limit)
 *   3. Transaction count
 *
 * ┌─────────────────────────────────────────────────────────────┐
 * │ MOOD         │ TRIGGER                  │ BG         │ Dragon │
 * ├─────────────────────────────────────────────────────────────┤
 * │ SLEEPING     │ 0 txns + evening/night   │ bg_autumn  │ dragon_sleeping │
 * │ CALM_MORNING │ morning + spend <40%     │ bg_sakura  │ dragon_sakura   │
 * │ NORMAL       │ afternoon or spend 0–79% │ bg_cozy_red│ dragon_happy    │
 * │ OVERSPENT    │ spend ≥ 80% of limit     │ bg_volcano │ dragon_fire     │
 * └─────────────────────────────────────────────────────────────┘
 */
open class DragonWidgetProvider : AppWidgetProvider() {

    // Mood enum
    enum class WidgetMood { SLEEPING, CALM_MORNING, NORMAL, OVERSPENT }

    open fun getLayoutId(): Int = R.layout.dragon_widget_medium

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val componentName = ComponentName(context, javaClass)
        val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
        if (appWidgetIds != null && appWidgetIds.isNotEmpty()) {
            onUpdate(context, appWidgetManager, appWidgetIds)
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        val prefs: SharedPreferences = HomeWidgetPlugin.getData(context)

        val spent        = prefs.getInt("spent",        0)
        val transactions = prefs.getInt("transactions", 0)
        val limit        = prefs.getInt("limit",        2000)
        val leftToSpend  = prefs.getInt("leftToSpend",  limit)
        val weekTotal    = prefs.getInt("weekTotal",    0)

        for (widgetId in appWidgetIds) {
            val views = buildViews(context, spent, transactions, limit, leftToSpend, weekTotal)
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    /** Determine mood from time of day + spend ratio + txn count */
    fun determineMood(spent: Int, transactions: Int, limit: Int): WidgetMood {
        val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
        val spendPct = if (limit > 0) spent.toFloat() / limit else 0f

        return when {
            // Overspent always wins regardless of time
            spendPct >= 0.80f -> WidgetMood.OVERSPENT

            // No transactions at all → sleeping (especially evening/night)
            transactions == 0 -> WidgetMood.SLEEPING

            // Morning (5–11am) with low spend → sakura calm
            hour in 5..11 && spendPct < 0.40f -> WidgetMood.CALM_MORNING

            // Default: normal active state
            else -> WidgetMood.NORMAL
        }
    }

    open fun buildViews(
        context: Context,
        spent: Int,
        transactions: Int,
        limit: Int,
        leftToSpend: Int,
        weekTotal: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, getLayoutId())
        val mood = determineMood(spent, transactions, limit)

        // Pick background + dragon by mood
        val (bgRes, dragonRes) = moodAssets(mood)
        views.setImageViewResource(R.id.widget_bg, bgRes)
        views.setImageViewResource(R.id.dragon_image, dragonRes)

        // Spending amount
        views.setTextViewText(R.id.amount_big, "₹${formatAmount(spent)}")

        // Limit badge
        val pct = if (limit > 0) ((spent.toFloat() / limit) * 100).toInt().coerceIn(0, 100) else 0
        views.setTextViewText(R.id.limit_badge, "of ₹${formatAmount(limit)} limit  ($pct%)")

        // Bottom stats
        views.setTextViewText(R.id.week_text, "₹${formatAmount(weekTotal)}")
        views.setTextViewText(R.id.txn_text,  "$transactions")

        // Mood label on spend_label
        val label = when (mood) {
            WidgetMood.SLEEPING     -> "All Quiet Today"
            WidgetMood.CALM_MORNING -> "Good Morning ☀"
            WidgetMood.NORMAL       -> "Spent Today"
            WidgetMood.OVERSPENT    -> "Budget Alert 🔥"
        }
        views.setTextViewText(R.id.spend_label, label)

        // Tap to open app
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 0, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }

    private fun moodAssets(mood: WidgetMood): Pair<Int, Int> = when (mood) {
        WidgetMood.SLEEPING     -> Pair(R.drawable.bg_autumn_red,  R.drawable.dragon_sleeping)
        WidgetMood.CALM_MORNING -> Pair(R.drawable.bg_sakura_pink, R.drawable.dragon_sakura)
        WidgetMood.NORMAL       -> Pair(R.drawable.bg_cozy_red,    R.drawable.dragon_happy)
        WidgetMood.OVERSPENT    -> Pair(R.drawable.bg_volcano_fire, R.drawable.dragon_fire)
    }

    protected fun formatAmount(n: Int): String {
        return when {
            n >= 100_000 -> "${n / 100_000}L"
            n >= 1_000   -> "${n / 1_000},${ "%03d".format(n % 1_000) }"
            else         -> n.toString()
        }
    }
}

/**
 * Small 2×2 Widget Provider
 */
class DragonWidgetSmallProvider : DragonWidgetProvider() {

    override fun getLayoutId(): Int = R.layout.dragon_widget_small

    override fun buildViews(
        context: Context,
        spent: Int,
        transactions: Int,
        limit: Int,
        leftToSpend: Int,
        weekTotal: Int,
    ): RemoteViews {
        val views = RemoteViews(context.packageName, getLayoutId())
        val mood = determineMood(spent, transactions, limit)

        val (bgRes, dragonRes) = when (mood) {
            WidgetMood.SLEEPING     -> Pair(R.drawable.bg_autumn_red,   R.drawable.dragon_sleeping)
            WidgetMood.CALM_MORNING -> Pair(R.drawable.bg_sakura_pink,  R.drawable.dragon_sakura)
            WidgetMood.NORMAL       -> Pair(R.drawable.bg_cozy_red,     R.drawable.dragon_happy)
            WidgetMood.OVERSPENT    -> Pair(R.drawable.bg_volcano_fire,  R.drawable.dragon_fire)
        }

        views.setImageViewResource(R.id.widget_bg, bgRes)
        views.setImageViewResource(R.id.dragon_image, dragonRes)
        views.setTextViewText(R.id.amount_text, "₹${formatAmount(spent)}")

        val pct = if (limit > 0) ((spent.toFloat() / limit) * 100).toInt().coerceIn(0, 100) else 0
        val badgeStr = when (mood) {
            WidgetMood.SLEEPING     -> "Zzz..."
            WidgetMood.CALM_MORNING -> "Morning ☀"
            WidgetMood.NORMAL       -> "$pct% used"
            WidgetMood.OVERSPENT    -> "⚠ $pct% limit!"
        }
        views.setTextViewText(R.id.badge_text, badgeStr)

        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context, 1, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

        return views
    }
}
