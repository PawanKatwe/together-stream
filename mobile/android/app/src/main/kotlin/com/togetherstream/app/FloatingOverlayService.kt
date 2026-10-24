package com.togetherstream.app

import android.animation.ValueAnimator
import android.annotation.SuppressLint
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.util.DisplayMetrics
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.TextView

class FloatingOverlayService : Service() {

    private var windowManager: WindowManager? = null
    private var floatingView: FrameLayout? = null
    private var params: WindowManager.LayoutParams? = null

    companion object {
        const val ACTION_SHOW = "com.togetherstream.app.SHOW_OVERLAY"
        const val ACTION_HIDE = "com.togetherstream.app.HIDE_OVERLAY"
        const val EXTRA_PARTNER_NAME = "extra_partner_name"

        fun start(context: Context, partnerName: String) {
            val intent = Intent(context, FloatingOverlayService::class.java).apply {
                action = ACTION_SHOW
                putExtra(EXTRA_PARTNER_NAME, partnerName)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            val intent = Intent(context, FloatingOverlayService::class.java).apply {
                action = ACTION_HIDE
            }
            context.startService(intent)
        }
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_SHOW -> {
                val partnerName = intent.getStringExtra(EXTRA_PARTNER_NAME) ?: "Partner"
                showFloatingBubble(partnerName)
            }
            ACTION_HIDE -> {
                removeFloatingBubble()
                stopSelf()
            }
        }
        return START_NOT_STICKY
    }

    @SuppressLint("ClickableViewAccessibility")
    private fun showFloatingBubble(partnerName: String) {
        if (floatingView != null) return

        windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

        val layoutFlag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_PHONE
        }

        val bubbleSizeDp = 76
        val density = resources.displayMetrics.density
        val bubbleSizePx = (bubbleSizeDp * density).toInt()

        params = WindowManager.LayoutParams(
            bubbleSizePx,
            bubbleSizePx,
            layoutFlag,
            WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                    WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
            PixelFormat.TRANSLUCENT
        ).apply {
            gravity = Gravity.TOP or Gravity.START
            x = 20
            y = 150
        }

        floatingView = FrameLayout(this).apply {
            // Romantic Rose Background Shape
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.OVAL
                setColor(Color.parseColor("#1D171E"))
                setStroke((2.5f * density).toInt(), Color.parseColor("#E2849C"))
            }
            background = shape

            // Center Partner Label / Initial
            val label = TextView(context).apply {
                text = "${partnerName.firstOrNull() ?: 'P'} ❤️"
                setTextColor(Color.parseColor("#F7A8BE"))
                textSize = 18f
                gravity = Gravity.CENTER
            }
            val lp = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT,
                Gravity.CENTER
            )
            addView(label, lp)
        }

        val displayMetrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        windowManager?.defaultDisplay?.getMetrics(displayMetrics)
        val screenWidth = displayMetrics.widthPixels

        var initialX = 0
        var initialY = 0
        var initialTouchX = 0f
        var initialTouchY = 0f
        var isClick = false

        floatingView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params!!.x
                    initialY = params!!.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    isClick = true
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()
                    if (Math.abs(deltaX) > 10 || Math.abs(deltaY) > 10) {
                        isClick = false
                    }
                    params!!.x = initialX + deltaX
                    params!!.y = initialY + deltaY
                    windowManager?.updateViewLayout(floatingView, params)
                    true
                }
                MotionEvent.ACTION_UP -> {
                    if (isClick) {
                        // Tap to expand / return to app
                        val launchIntent = Intent(this, MainActivity::class.java).apply {
                            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                        }
                        startActivity(launchIntent)
                    } else {
                        // Snap smoothly to left or right screen edge
                        val targetX = if (params!!.x + (bubbleSizePx / 2) < screenWidth / 2) {
                            16 // Snap to Left Margin
                        } else {
                            screenWidth - bubbleSizePx - 16 // Snap to Right Margin
                        }

                        val animator = ValueAnimator.ofInt(params!!.x, targetX).apply {
                            duration = 200
                            addUpdateListener { anim ->
                                params!!.x = anim.animatedValue as Int
                                windowManager?.updateViewLayout(floatingView, params)
                            }
                        }
                        animator.start()
                    }
                    true
                }
                else -> false
            }
        }

        try {
            windowManager?.addView(floatingView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun removeFloatingBubble() {
        if (floatingView != null) {
            try {
                windowManager?.removeView(floatingView)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            floatingView = null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        removeFloatingBubble()
    }
}
