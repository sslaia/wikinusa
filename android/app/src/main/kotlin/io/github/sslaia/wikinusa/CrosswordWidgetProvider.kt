package io.github.sslaia.wikinusa

import android.content.Context
import android.content.SharedPreferences
import android.graphics.*
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

class CrosswordWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: android.appwidget.AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_crossword).apply {
                val title = widgetData.getString("crossword_title", "DAILY CROSSWORD") ?: "DAILY CROSSWORD"
                val puzzleId = widgetData.getString("crossword_puzzle_id", "") ?: ""
                val sampleClue = widgetData.getString("crossword_sample_clue", "Tap to solve today's crossword puzzle!") ?: "Tap to solve today's crossword puzzle!"

                val fullTitle = if (puzzleId.isNotEmpty()) "$title $puzzleId" else title
                setTextViewText(R.id.widget_title, fullTitle)
                setTextViewText(R.id.widget_clue, sampleClue)

                // Always generate clean native Android Canvas crossword grid bitmap
                val gridBitmap = createDefaultGridBitmap()
                try {
                    setImageViewBitmap(R.id.widget_crossword_image, gridBitmap)
                } catch (e: Exception) {
                    e.printStackTrace()
                }

                val intent = HomeWidgetLaunchIntent.getActivity(
                    context,
                    MainActivity::class.java,
                    Uri.parse("wikinusa://crossword")
                )
                setOnClickPendingIntent(R.id.widget_container, intent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun createDefaultGridBitmap(): Bitmap {
        val width = 360
        val height = 360
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)

        val bgPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#0F172A"); style = Paint.Style.FILL }
        val bgRect = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(bgRect, 24f, 24f, bgPaint)

        val size = 7
        val padding = 20f
        val cellSize = (width - padding * 2) / size

        val cellPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.WHITE; style = Paint.Style.FILL }
        val wallPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { color = Color.parseColor("#1E293B"); style = Paint.Style.FILL }
        val numPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = Color.parseColor("#475569")
            textSize = 14f
            typeface = Typeface.create("sans-serif-medium", Typeface.BOLD)
        }

        val grid = arrayOf(
            intArrayOf(1, 1, 1, 0, 1, 1, 1),
            intArrayOf(1, 0, 1, 0, 1, 0, 1),
            intArrayOf(1, 1, 1, 1, 1, 1, 1),
            intArrayOf(0, 1, 0, 1, 0, 1, 0),
            intArrayOf(1, 1, 1, 1, 1, 1, 1),
            intArrayOf(1, 0, 1, 0, 1, 0, 1),
            intArrayOf(1, 1, 1, 0, 1, 1, 1)
        )

        var cellNumber = 1
        for (row in 0 until size) {
            for (col in 0 until size) {
                val left = padding + col * cellSize
                val top = padding + row * cellSize
                val right = left + cellSize - 3
                val bottom = top + cellSize - 3

                val rect = RectF(left, top, right, bottom)
                if (grid[row][col] == 1) {
                    canvas.drawRoundRect(rect, 6f, 6f, cellPaint)
                    if (row == 0 || col == 0 || (row % 2 == 0 && col % 2 == 0)) {
                        canvas.drawText("$cellNumber", left + 5f, top + 15f, numPaint)
                        cellNumber++
                    }
                } else {
                    canvas.drawRoundRect(rect, 6f, 6f, wallPaint)
                }
            }
        }
        return bitmap
    }
}
