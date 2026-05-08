package com.example.multi_ads.pangle_global

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Color
import android.graphics.Outline
import android.graphics.Typeface
import android.util.Log
import android.util.TypedValue
import android.view.View
import android.view.ViewOutlineProvider
import android.widget.FrameLayout
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAd
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAdInteractionListener
import java.net.URL

class NativeAdViewFactory(
    private val handler: PangleAdsHandler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val creationParams = args as? Map<String, Any>
        return NativeAdPlatformView(context, creationParams, handler)
    }
}

class NativeAdPlatformView(
    private val context: Context,
    creationParams: Map<String, Any>?,
    private val handler: PangleAdsHandler
) : PlatformView {

    companion object {
        const val TAG = "PangleNativeAdView"
    }

    private val container: FrameLayout = FrameLayout(context)
    private val listenerId: String = (creationParams?.get("listenerId") as? String) ?: ""

    init {
        @Suppress("UNCHECKED_CAST")
        val style = creationParams?.get("style") as? Map<String, Any> ?: emptyMap()
        val nativeAd = handler.getNativeAd(listenerId)

        if (nativeAd != null) {
            Log.d(TAG, "Building native ad view for listenerId: $listenerId")
            buildNativeAdView(nativeAd, style)
        } else {
            Log.w(TAG, "Native ad not loaded yet for listenerId: $listenerId")
        }
    }
    private fun buildNativeAdView(nativeAd: PAGNativeAd, style: Map<String, Any>) {
        val density = context.resources.displayMetrics.density

        // Read style options
        val height = (style["height"] as? Double)?.toInt() ?: 80
        val imageWidth = (style["imageWidth"] as? Double)?.toInt() ?: 120
        val imageHeight = (style["imageHeight"] as? Double)?.toInt() ?: height
        val titleFontSize = (style["titleFontSize"] as? Double)?.toFloat() ?: 14f
        val titleColorStr = style["titleColor"] as? String ?: "#FF202124"
        val titleBold = style["titleBold"] as? Boolean ?: true
        val titleMaxLines = (style["titleMaxLines"] as? Int) ?: 2
        val titleFontFamily = style["titleFontFamily"] as? String
        val bodyFontSize = (style["bodyFontSize"] as? Double)?.toFloat() ?: 10f
        val bodyColorStr = style["bodyColor"] as? String ?: "#FF999999"
        val bodyBold = style["bodyBold"] as? Boolean ?: false
        val bodyFontFamily = style["bodyFontFamily"] as? String
        val bgColorStr = style["backgroundColor"] as? String ?: "#FFFFFFFF"
        val cornerRadius = (style["cornerRadius"] as? Double)?.toFloat() ?: 10f
        val imageCornerRadius = (style["imageCornerRadius"] as? Double)?.toFloat() ?: 0f
        val textPadH = (style["textPaddingHorizontal"] as? Double)?.toInt() ?: 12
        val textPadV = (style["textPaddingVertical"] as? Double)?.toInt() ?: 8
        val textAlignment = style["textAlignment"] as? String ?: "center"
        val showStarRating = style["showStarRating"] as? Boolean ?: true
        val starSize = (style["starSize"] as? Double)?.toFloat() ?: 12f
        val starActiveColorStr = style["starActiveColor"] as? String ?: "#FFFFC107"
        val starInactiveColorStr = style["starInactiveColor"] as? String ?: "#FFCCCCCC"
        val showCallToAction = style["showCallToAction"] as? Boolean ?: true
        val ctaFontSize = (style["ctaFontSize"] as? Double)?.toFloat() ?: 12f
        val ctaTextColorStr = style["ctaTextColor"] as? String ?: "#FFFFFFFF"
        val ctaBgColorStr = style["ctaBackgroundColor"] as? String ?: "#FF4285F4"
        val ctaCornerRadius = (style["ctaCornerRadius"] as? Double)?.toFloat() ?: 4f
        val ctaBold = style["ctaBold"] as? Boolean ?: true
        val ctaPadH = (style["ctaPaddingHorizontal"] as? Double)?.toFloat() ?: 8f

        val titleColor = parseColor(titleColorStr)
        val bodyColor = parseColor(bodyColorStr)
        val bgColor = parseColor(bgColorStr)

        // Get native ad data
        val nativeAdData = nativeAd.nativeAdData
        val title = nativeAdData?.title ?: ""
        val description = nativeAdData?.description ?: ""
        val iconUrl = nativeAdData?.icon?.imageUrl
        val callToAction = nativeAdData?.buttonText

        // Root container
        val adView = LinearLayout(context)
        adView.orientation = LinearLayout.HORIZONTAL
        adView.layoutParams = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            (height * density).toInt()
        )
        adView.setBackgroundColor(bgColor)

        // Corner radius
        if (cornerRadius > 0) {
            val radiusPx = cornerRadius * density
            adView.outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, radiusPx)
                }
            }
            adView.clipToOutline = true
        }

        // Icon image
        val iconView = ImageView(context)
        iconView.layoutParams = LinearLayout.LayoutParams(
            (imageWidth * density).toInt(),
            (imageHeight * density).toInt()
        )
        iconView.scaleType = ImageView.ScaleType.CENTER_CROP
        if (imageCornerRadius > 0) {
            val imgRadiusPx = imageCornerRadius * density
            iconView.outlineProvider = object : ViewOutlineProvider() {
                override fun getOutline(view: View, outline: Outline) {
                    outline.setRoundRect(0, 0, view.width, view.height, imgRadiusPx)
                }
            }
            iconView.clipToOutline = true
        }
        if (!iconUrl.isNullOrEmpty()) {
            Thread {
                try {
                    val stream = URL(iconUrl).openStream()
                    val bitmap = BitmapFactory.decodeStream(stream)
                    stream.close()
                    iconView.post { iconView.setImageBitmap(bitmap) }
                } catch (e: Exception) {
                    Log.w(TAG, "Failed to load icon from URL: $iconUrl", e)
                }
            }.start()
        }
        adView.addView(iconView)

        // Text container
        val textContainer = LinearLayout(context)
        textContainer.orientation = LinearLayout.VERTICAL
        textContainer.gravity = when (textAlignment) {
            "start" -> android.view.Gravity.TOP
            "end" -> android.view.Gravity.BOTTOM
            "center" -> android.view.Gravity.CENTER_VERTICAL
            else -> android.view.Gravity.CENTER_VERTICAL
        }
        val textParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        textContainer.layoutParams = textParams
        textContainer.setPadding(
            (textPadH * density).toInt(),
            (textPadV * density).toInt(),
            (textPadH * density).toInt(),
            (textPadV * density).toInt()
        )
        adView.addView(textContainer)

        // Top spacer for space modes
        if (textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
            val topSpacer = View(context)
            topSpacer.layoutParams = LinearLayout.LayoutParams(0, 0, if (textAlignment == "spaceAround") 0.5f else 1f)
            textContainer.addView(topSpacer)
        }

        // Headline
        val headlineView = TextView(context)
        headlineView.setTextSize(TypedValue.COMPLEX_UNIT_SP, titleFontSize)
        headlineView.setTextColor(titleColor)
        val titleTypeface = if (titleFontFamily != null) {
            try { Typeface.create(titleFontFamily, if (titleBold) Typeface.BOLD else Typeface.NORMAL) }
            catch (e: Exception) { if (titleBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT }
        } else {
            if (titleBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        headlineView.typeface = titleTypeface
        headlineView.maxLines = titleMaxLines
        headlineView.ellipsize = android.text.TextUtils.TruncateAt.END
        headlineView.text = title
        textContainer.addView(headlineView)

        // Middle spacer
        if (textAlignment == "spaceBetween" || textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
            val midSpacer = View(context)
            midSpacer.layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
            textContainer.addView(midSpacer)
        }

        // Body
        val bodyView = TextView(context)
        bodyView.setTextSize(TypedValue.COMPLEX_UNIT_SP, bodyFontSize)
        bodyView.setTextColor(bodyColor)
        val bodyTypeface = if (bodyFontFamily != null) {
            try { Typeface.create(bodyFontFamily, if (bodyBold) Typeface.BOLD else Typeface.NORMAL) }
            catch (e: Exception) { if (bodyBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT }
        } else {
            if (bodyBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
        }
        bodyView.typeface = bodyTypeface
        bodyView.maxLines = 1
        bodyView.ellipsize = android.text.TextUtils.TruncateAt.END
        bodyView.text = description
        val bodyParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        if (textAlignment != "spaceBetween" && textAlignment != "spaceAround" && textAlignment != "spaceEvenly") {
            bodyParams.topMargin = (4 * density).toInt()
        }
        bodyView.layoutParams = bodyParams
        textContainer.addView(bodyView)

        // CTA button
        val hasCta = showCallToAction && callToAction != null && callToAction.isNotEmpty()

        if (hasCta) {
            if (textAlignment != "spaceBetween" && textAlignment != "spaceAround" && textAlignment != "spaceEvenly") {
                val marginView = View(context)
                marginView.layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (4 * density).toInt()
                )
                textContainer.addView(marginView)
            }

            val bottomRow = LinearLayout(context)
            bottomRow.orientation = LinearLayout.HORIZONTAL
            bottomRow.gravity = android.view.Gravity.CENTER_VERTICAL
            bottomRow.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            // Spacer to push CTA to right
            val spacer = View(context)
            spacer.layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
            bottomRow.addView(spacer)

            val ctaTextColor = parseColor(ctaTextColorStr)
            val ctaBgColor = parseColor(ctaBgColorStr)
            val ctaView = TextView(context)
            ctaView.text = callToAction
            ctaView.setTextSize(TypedValue.COMPLEX_UNIT_SP, ctaFontSize)
            ctaView.setTextColor(ctaTextColor)
            ctaView.typeface = if (ctaBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
            ctaView.setPadding(
                (ctaPadH * density).toInt(), (4 * density).toInt(),
                (ctaPadH * density).toInt(), (4 * density).toInt()
            )

            val ctaDrawable = android.graphics.drawable.GradientDrawable()
            ctaDrawable.setColor(ctaBgColor)
            ctaDrawable.cornerRadius = ctaCornerRadius * density
            ctaView.background = ctaDrawable

            bottomRow.addView(ctaView)
            textContainer.addView(bottomRow)
        }

        // Bottom spacer for space modes
        if (textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
            val bottomSpacer = View(context)
            bottomSpacer.layoutParams = LinearLayout.LayoutParams(0, 0, if (textAlignment == "spaceAround") 0.5f else 1f)
            textContainer.addView(bottomSpacer)
        }

        container.removeAllViews()
        container.addView(adView)

        // Register click interaction with 7.x API
        val eventSink = handler.getNativeEventSink()
        nativeAd.registerViewForInteraction(
            container,
            listOf<View>(container),
            listOf<View>(),
            null,
            object : PAGNativeAdInteractionListener {
                override fun onAdShowed() {
                    Log.d(TAG, "Native ad showed")
                    eventSink?.success(mapOf("listenerId" to listenerId, "event" to "onAdShowed"))
                }

                override fun onAdClicked() {
                    Log.d(TAG, "Native ad clicked")
                    eventSink?.success(mapOf("listenerId" to listenerId, "event" to "onAdClicked"))
                }

                override fun onAdDismissed() {
                    Log.d(TAG, "Native ad dismissed")
                }
            }
        )
    }

    private fun parseColor(colorStr: String): Int {
        return try {
            Color.parseColor(colorStr)
        } catch (e: Exception) {
            Color.WHITE
        }
    }

    override fun getView(): View = container

    override fun dispose() {
        container.removeAllViews()
    }
}
