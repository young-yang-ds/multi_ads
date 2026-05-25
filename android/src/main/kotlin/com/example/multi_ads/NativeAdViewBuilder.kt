package com.example.multi_ads

import android.content.Context
import android.graphics.Color
import android.graphics.Outline
import android.graphics.Typeface
import android.util.TypedValue
import android.view.View
import android.view.ViewOutlineProvider
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.TextView
import com.google.android.gms.ads.nativead.NativeAd
import com.google.android.gms.ads.nativead.NativeAdView

/// Builds a styled NativeAdView from a NativeAd and customOptions map.
///
/// This class reads styling parameters from the customOptions map passed by
/// the Dart side via [NativeAdStyle.toMap()], so all styling is controlled from Dart.
///
/// Usage in your app's NativeAdFactory:
/// ```kotlin
/// class MyFactory(ctx: Context) : GoogleMobileAdsPlugin.NativeAdFactory {
///     private val builder = NativeAdViewBuilder(ctx)
///     override fun createNativeAd(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?) =
///         builder.build(nativeAd, customOptions)
/// }
/// ```
class NativeAdViewBuilder(private val context: Context) {
    fun build(nativeAd: NativeAd, customOptions: MutableMap<String, Any>?): NativeAdView {
        val density = context.resources.displayMetrics.density
        val options = customOptions ?: mutableMapOf()

        // Read style options from Dart NativeAdStyle
        val height = (options["height"] as? Double)?.toInt() ?: 80
        val imageWidth = (options["imageWidth"] as? Double)?.toInt() ?: 120
        val imageHeight = (options["imageHeight"] as? Double)?.toInt() ?: height
        val titleFontSize = (options["titleFontSize"] as? Double)?.toFloat() ?: 14f
        val titleColorStr = options["titleColor"] as? String ?: "#FF202124"
        val titleBold = options["titleBold"] as? Boolean ?: true
        val titleMaxLines = (options["titleMaxLines"] as? Int) ?: 2
        val titleFontFamily = options["titleFontFamily"] as? String
        val bodyFontSize = (options["bodyFontSize"] as? Double)?.toFloat() ?: 10f
        val bodyColorStr = options["bodyColor"] as? String ?: "#FF999999"
        val bodyBold = options["bodyBold"] as? Boolean ?: false
        val bodyFontFamily = options["bodyFontFamily"] as? String
        val bgColorStr = options["backgroundColor"] as? String ?: "#FFFFFFFF"
        val cornerRadius = (options["cornerRadius"] as? Double)?.toFloat() ?: 10f
        val imageCornerRadius = (options["imageCornerRadius"] as? Double)?.toFloat() ?: 0f
        val textPadH = (options["textPaddingHorizontal"] as? Double)?.toInt() ?: 12
        val textPadV = (options["textPaddingVertical"] as? Double)?.toInt() ?: 8
        val textAlignment = options["textAlignment"] as? String ?: "center"
        val showStarRating = options["showStarRating"] as? Boolean ?: true
        val starSize = (options["starSize"] as? Double)?.toFloat() ?: 12f
        val starActiveColorStr = options["starActiveColor"] as? String ?: "#FFFFC107"
        val starInactiveColorStr = options["starInactiveColor"] as? String ?: "#FFCCCCCC"
        val showCallToAction = options["showCallToAction"] as? Boolean ?: true
        val ctaFontSize = (options["ctaFontSize"] as? Double)?.toFloat() ?: 12f
        val ctaTextColorStr = options["ctaTextColor"] as? String ?: "#FFFFFFFF"
        val ctaBgColorStr = options["ctaBackgroundColor"] as? String ?: "#FF4285F4"
        val ctaCornerRadius = (options["ctaCornerRadius"] as? Double)?.toFloat() ?: 4f
        val ctaBold = options["ctaBold"] as? Boolean ?: true
        val ctaPadH = (options["ctaPaddingHorizontal"] as? Double)?.toFloat() ?: 8f
        val layoutMode = options["layoutMode"] as? String ?: "horizontal"

        val titleColor = parseColor(titleColorStr)
        val bodyColor = parseColor(bodyColorStr)
        val bgColor = parseColor(bgColorStr)

        // NativeAdView
        val adView = NativeAdView(context)
        adView.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
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

        // === Vertical layout branch (full-screen native ad) ===
        if (layoutMode == "vertical") {
            // Main image controls
            val mainImageHeightDp = (options["mainImageHeight"] as? Double)?.toFloat() ?: imageHeight.toFloat()
            val mainImageScaleMode = options["mainImageScaleMode"] as? String ?: "cover"
            val mainImageCornerRadius = (options["mainImageCornerRadius"] as? Double)?.toFloat() ?: 0f
            val mainImageBgStr = options["mainImageBackgroundColor"] as? String ?: "#00000000"
            val mainImageSource = options["mainImageSource"] as? String ?: "auto"
            val mainImagePadL = (options["mainImagePaddingLeft"] as? Double)?.toFloat() ?: 0f
            val mainImagePadT = (options["mainImagePaddingTop"] as? Double)?.toFloat() ?: 0f
            val mainImagePadR = (options["mainImagePaddingRight"] as? Double)?.toFloat() ?: 0f
            val mainImagePadB = (options["mainImagePaddingBottom"] as? Double)?.toFloat() ?: 0f
            val verticalContentAlignment = options["verticalContentAlignment"] as? String ?: "top"

            val verticalContainer = LinearLayout(context)
            verticalContainer.orientation = LinearLayout.VERTICAL
            verticalContainer.gravity = when (verticalContentAlignment) {
                "center" -> android.view.Gravity.CENTER_VERTICAL
                "bottom" -> android.view.Gravity.BOTTOM
                else -> android.view.Gravity.TOP
            }
            verticalContainer.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
            )
            adView.addView(verticalContainer)

            // Main image (full width × mainImageHeight)
            val mainImage = ImageView(context)
            val mainImageParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                (mainImageHeightDp * density).toInt()
            )
            mainImageParams.setMargins(
                (mainImagePadL * density).toInt(),
                (mainImagePadT * density).toInt(),
                (mainImagePadR * density).toInt(),
                (mainImagePadB * density).toInt(),
            )
            mainImage.layoutParams = mainImageParams
            mainImage.scaleType = when (mainImageScaleMode) {
                "contain" -> ImageView.ScaleType.FIT_CENTER
                "fill" -> ImageView.ScaleType.FIT_XY
                else -> ImageView.ScaleType.CENTER_CROP
            }
            mainImage.setBackgroundColor(parseColor(mainImageBgStr))
            if (mainImageCornerRadius > 0) {
                val r = mainImageCornerRadius * density
                mainImage.outlineProvider = object : ViewOutlineProvider() {
                    override fun getOutline(view: View, outline: Outline) {
                        outline.setRoundRect(0, 0, view.width, view.height, r)
                    }
                }
                mainImage.clipToOutline = true
            }
            // Image source: auto = media first then icon; media = media only; icon = icon only
            val mainDrawable = when (mainImageSource) {
                "media" -> nativeAd.images?.firstOrNull()?.drawable
                "icon" -> nativeAd.icon?.drawable
                else -> nativeAd.images?.firstOrNull()?.drawable ?: nativeAd.icon?.drawable
            }
            mainDrawable?.let { mainImage.setImageDrawable(it) }
            verticalContainer.addView(mainImage)
            adView.iconView = mainImage

            // Icon + Headline row
            val titleRow = LinearLayout(context)
            titleRow.orientation = LinearLayout.HORIZONTAL
            titleRow.gravity = android.view.Gravity.CENTER_VERTICAL
            val titleRowParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            titleRowParams.topMargin = (textPadV * density).toInt()
            titleRowParams.leftMargin = (textPadH * density).toInt()
            titleRowParams.rightMargin = (textPadH * density).toInt()
            titleRow.layoutParams = titleRowParams

            // Small icon (40dp)
            val smallIcon = ImageView(context)
            val smallIconSize = (40 * density).toInt()
            val smallIconParams = LinearLayout.LayoutParams(smallIconSize, smallIconSize)
            smallIconParams.rightMargin = (8 * density).toInt()
            smallIcon.layoutParams = smallIconParams
            smallIcon.scaleType = ImageView.ScaleType.CENTER_CROP
            if (imageCornerRadius > 0) {
                val r = imageCornerRadius * density
                smallIcon.outlineProvider = object : ViewOutlineProvider() {
                    override fun getOutline(view: View, outline: Outline) {
                        outline.setRoundRect(0, 0, view.width, view.height, r)
                    }
                }
                smallIcon.clipToOutline = true
            }
            nativeAd.icon?.let { smallIcon.setImageDrawable(it.drawable) }
            titleRow.addView(smallIcon)

            // Headline
            val vHeadline = TextView(context)
            vHeadline.setTextSize(TypedValue.COMPLEX_UNIT_SP, titleFontSize)
            vHeadline.setTextColor(titleColor)
            val vTitleTypeface = if (titleFontFamily != null) {
                try { Typeface.create(titleFontFamily, if (titleBold) Typeface.BOLD else Typeface.NORMAL) }
                catch (e: Exception) { if (titleBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT }
            } else {
                if (titleBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
            }
            vHeadline.typeface = vTitleTypeface
            vHeadline.maxLines = titleMaxLines
            vHeadline.ellipsize = android.text.TextUtils.TruncateAt.END
            vHeadline.text = nativeAd.headline
            vHeadline.layoutParams = LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f
            )
            titleRow.addView(vHeadline)
            adView.headlineView = vHeadline

            verticalContainer.addView(titleRow)

            // Full-width CTA button
            if (showCallToAction && nativeAd.callToAction != null) {
                val vCta = TextView(context)
                vCta.text = nativeAd.callToAction
                vCta.setTextSize(TypedValue.COMPLEX_UNIT_SP, ctaFontSize)
                vCta.setTextColor(parseColor(ctaTextColorStr))
                vCta.typeface = if (ctaBold) Typeface.DEFAULT_BOLD else Typeface.DEFAULT
                vCta.gravity = android.view.Gravity.CENTER
                val ctaPadVPx = (8 * density).toInt()
                vCta.setPadding(
                    (ctaPadH * density).toInt(), ctaPadVPx,
                    (ctaPadH * density).toInt(), ctaPadVPx
                )
                val vCtaDrawable = android.graphics.drawable.GradientDrawable()
                vCtaDrawable.setColor(parseColor(ctaBgColorStr))
                vCtaDrawable.cornerRadius = ctaCornerRadius * density
                vCta.background = vCtaDrawable
                val vCtaParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                vCtaParams.topMargin = (textPadV * density).toInt()
                vCtaParams.leftMargin = (textPadH * density).toInt()
                vCtaParams.rightMargin = (textPadH * density).toInt()
                vCtaParams.bottomMargin = (textPadV * density).toInt()
                vCta.layoutParams = vCtaParams
                verticalContainer.addView(vCta)
                adView.callToActionView = vCta
            }

            adView.setNativeAd(nativeAd)
            return adView
        }

        // Horizontal container
        val container = LinearLayout(context)
        container.orientation = LinearLayout.HORIZONTAL
        container.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.MATCH_PARENT
        )
        adView.addView(container)

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
        container.addView(iconView)
        adView.iconView = iconView

        // Text container
        val textContainer = LinearLayout(context)
        textContainer.orientation = LinearLayout.VERTICAL
        textContainer.gravity = when (textAlignment) {
            "start" -> android.view.Gravity.TOP
            "end" -> android.view.Gravity.BOTTOM
            "center" -> android.view.Gravity.CENTER_VERTICAL
            else -> android.view.Gravity.CENTER_VERTICAL // spaceBetween/spaceAround/spaceEvenly handled after adding children
        }
        val textParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
        textContainer.layoutParams = textParams
        textContainer.setPadding(
            (textPadH * density).toInt(),
            (textPadV * density).toInt(),
            (textPadH * density).toInt(),
            (textPadV * density).toInt()
        )
        container.addView(textContainer)

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
        headlineView.text = nativeAd.headline

        // For space modes, add spacers
        if (textAlignment == "spaceBetween" || textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
            // Top spacer (for spaceAround and spaceEvenly)
            if (textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
                val topSpacer = View(context)
                topSpacer.layoutParams = LinearLayout.LayoutParams(0, 0, if (textAlignment == "spaceAround") 0.5f else 1f)
                textContainer.addView(topSpacer, 0) // insert before headline
            }
        }

        textContainer.addView(headlineView)
        adView.headlineView = headlineView

        // Middle spacer (for spaceBetween, spaceAround, spaceEvenly)
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
        bodyView.text = nativeAd.body
        val bodyParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
        if (textAlignment != "spaceBetween" && textAlignment != "spaceAround" && textAlignment != "spaceEvenly") {
            bodyParams.topMargin = (4 * density).toInt()
        }
        bodyView.layoutParams = bodyParams
        textContainer.addView(bodyView)
        adView.bodyView = bodyView

        // Star rating row + CTA button in a horizontal row
        val starRating = nativeAd.starRating
        val callToAction = nativeAd.callToAction
        val hasStarRating = showStarRating && starRating != null
        val hasCta = showCallToAction && callToAction != null

        if (hasStarRating || hasCta) {
            // Bottom row spacer (between body and bottom row)
            if (textAlignment != "spaceBetween" && textAlignment != "spaceAround" && textAlignment != "spaceEvenly") {
                val bottomRowMarginView = View(context)
                bottomRowMarginView.layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT, (4 * density).toInt()
                )
                textContainer.addView(bottomRowMarginView)
            }

            val bottomRow = LinearLayout(context)
            bottomRow.orientation = LinearLayout.HORIZONTAL
            bottomRow.gravity = android.view.Gravity.CENTER_VERTICAL
            bottomRow.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )

            // Star rating
            if (hasStarRating) {
                val starActiveColor = parseColor(starActiveColorStr)
                val starInactiveColor = parseColor(starInactiveColorStr)
                val starsView = TextView(context)
                starsView.setTextSize(TypedValue.COMPLEX_UNIT_SP, starSize)
                val rating = starRating!!.toFloat()
                val fullStars = rating.toInt()
                val sb = StringBuilder()
                for (i in 1..5) {
                    sb.append(if (i <= fullStars) "★" else "☆")
                }
                starsView.text = sb.toString()

                // Use SpannableString for colored stars
                val spannable = android.text.SpannableString(sb.toString())
                for (i in 0 until 5) {
                    val color = if (i < fullStars) starActiveColor else starInactiveColor
                    spannable.setSpan(
                        android.text.style.ForegroundColorSpan(color),
                        i, i + 1,
                        android.text.Spannable.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                starsView.text = spannable
                bottomRow.addView(starsView)
                adView.starRatingView = starsView
            }

            // Spacer between stars and CTA
            if (hasStarRating && hasCta) {
                val spacer = View(context)
                spacer.layoutParams = LinearLayout.LayoutParams(0, 0, 1f)
                bottomRow.addView(spacer)
            }

            // CTA button
            if (hasCta) {
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

                // Background with corner radius
                val ctaDrawable = android.graphics.drawable.GradientDrawable()
                ctaDrawable.setColor(ctaBgColor)
                ctaDrawable.cornerRadius = ctaCornerRadius * density
                ctaView.background = ctaDrawable

                bottomRow.addView(ctaView)
                adView.callToActionView = ctaView
            }

            textContainer.addView(bottomRow)
        }

        // Bottom spacer (for spaceAround and spaceEvenly)
        if (textAlignment == "spaceAround" || textAlignment == "spaceEvenly") {
            val bottomSpacer = View(context)
            bottomSpacer.layoutParams = LinearLayout.LayoutParams(0, 0, if (textAlignment == "spaceAround") 0.5f else 1f)
            textContainer.addView(bottomSpacer)
        }

        // Bind icon
        nativeAd.icon?.let {
            iconView.setImageDrawable(it.drawable)
        }

        adView.setNativeAd(nativeAd)
        return adView
    }

    private fun parseColor(colorStr: String): Int {
        return try {
            Color.parseColor(colorStr)
        } catch (e: Exception) {
            Color.WHITE
        }
    }
}
