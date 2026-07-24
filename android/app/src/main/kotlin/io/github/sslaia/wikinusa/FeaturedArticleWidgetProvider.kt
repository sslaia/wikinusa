package io.github.sslaia.wikinusa

import android.content.Context
import android.content.SharedPreferences
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class FeaturedArticleWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_featured_article).apply {
                val projects = listOf("wikipedia", "wiktionary", "wikibooks")
                val storedProjects = projects.filter { proj ->
                    !widgetData.getString("featured_article_title_$proj", null).isNullOrEmpty()
                }

                val label: String
                val articleTitle: String
                val snippet: String

                if (storedProjects.isNotEmpty()) {
                    val currentIndex = (widgetData.getInt("featured_article_cycle_index", 0) + 1) % storedProjects.size
                    widgetData.edit().putInt("featured_article_cycle_index", currentIndex).apply()
                    val selectedProj = storedProjects[currentIndex]

                    label = widgetData.getString("featured_article_label_$selectedProj", "FEATURED ARTICLE") ?: "FEATURED ARTICLE"
                    articleTitle = widgetData.getString("featured_article_title_$selectedProj", "") ?: ""
                    snippet = widgetData.getString("featured_article_snippet_$selectedProj", "") ?: ""
                } else {
                    label = widgetData.getString("featured_article_label", "FEATURED ARTICLE") ?: "FEATURED ARTICLE"
                    articleTitle = widgetData.getString("featured_article_title", "") ?: ""
                    snippet = widgetData.getString("featured_article_snippet", "Explore today's featured content on WikiNusa.") ?: "Explore today's featured content on WikiNusa."
                }

                setTextViewText(R.id.widget_title, label)
                setTextViewText(R.id.widget_article_title, articleTitle)
                setTextViewText(R.id.widget_snippet, snippet)

                val intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("wikinusa://featured_article")
                )
                setOnClickPendingIntent(R.id.widget_container, intent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
