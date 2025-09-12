package com.example.myproject  // ← 너의 패키지명과 정확히 일치시켜줘

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.util.Log
import android.widget.RemoteViews
import com.example.myproject.R
import es.antonborri.home_widget.HomeWidgetProvider

class HomeDashboardWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (id in appWidgetIds) {
            updateSafe(context, appWidgetManager, id, widgetData)
        }
    }

    private fun updateSafe(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        data: SharedPreferences
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_dashboard)
        try {
            // 기본 하드코딩(최소 표시)
            views.setTextViewText(R.id.assign1, "위젯 로드 테스트")

            // 실제 데이터 적용
            val assignsJson = data.getString("assignments_json", "[]") ?: "[]"
            val videosJson  = data.getString("videos_json", "[]") ?: "[]"

            val assigns = try { org.json.JSONArray(assignsJson) } catch (e: Exception) {
                Log.e("WIDGET", "assigns JSON error", e); org.json.JSONArray()
            }
            val videos  = try { org.json.JSONArray(videosJson) } catch (e: Exception) {
                Log.e("WIDGET", "videos JSON error", e); org.json.JSONArray()
            }

            fun getOrEmpty(a: org.json.JSONArray, i: Int) =
                if (i < a.length()) a.optString(i, "") else ""

            views.setTextViewText(R.id.assign1, getOrEmpty(assigns, 0))
            views.setTextViewText(R.id.assign2, getOrEmpty(assigns, 1))
            views.setTextViewText(R.id.assign3, getOrEmpty(assigns, 2))
            views.setTextViewText(R.id.assign4, getOrEmpty(assigns, 3))

            views.setTextViewText(R.id.video1, getOrEmpty(videos, 0))
            views.setTextViewText(R.id.video2, getOrEmpty(videos, 1))
            views.setTextViewText(R.id.video3, getOrEmpty(videos, 2))
            views.setTextViewText(R.id.video4, getOrEmpty(videos, 3))

            // 클릭 → 앱 실행
            val launch = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pi = PendingIntent.getActivity(
                context, 0, launch,
                PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            views.setOnClickPendingIntent(R.id.root, pi)

        } catch (t: Throwable) {
            Log.e("WIDGET", "update error", t)
            views.setTextViewText(R.id.assign1, "데이터를 불러오지 못했어요")
        }
        manager.updateAppWidget(appWidgetId, views)
    }
}
