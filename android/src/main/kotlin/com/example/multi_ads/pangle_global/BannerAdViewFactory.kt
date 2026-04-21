package com.example.multi_ads.pangle_global

import android.content.Context
import android.view.View
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAd
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAdLoadListener
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAdInteractionListener
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerRequest
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerSize
import android.widget.FrameLayout

class BannerAdViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return BannerAdView(context, messenger, creationParams)
    }
}

class BannerAdView(
    private val context: Context,
    messenger: BinaryMessenger,
    creationParams: Map<String, Any>?
) : PlatformView {
    private val container: FrameLayout = FrameLayout(context)
    private var bannerAd: PAGBannerAd? = null
    private val channel = MethodChannel(messenger, "multi_ads/pangle_global")

    init {
        val slotId = creationParams?.get("slotId") as? String ?: ""
        val adSizeIndex = creationParams?.get("adSize") as? Int ?: 0
        
        loadBannerAd(slotId, adSizeIndex)
    }

    private fun loadBannerAd(slotId: String, adSizeIndex: Int) {
        val bannerSize = when (adSizeIndex) {
            0 -> PAGBannerSize.BANNER_W_320_H_50
            1 -> PAGBannerSize.BANNER_W_300_H_250
            2 -> PAGBannerSize.BANNER_W_728_H_90
            3 -> {
                val screenWidth = context.resources.displayMetrics.widthPixels
                val density = context.resources.displayMetrics.density
                val widthDp = (screenWidth / density).toInt()
                PAGBannerSize(widthDp, 0)
            }
            else -> PAGBannerSize.BANNER_W_320_H_50
        }
        
        val request = PAGBannerRequest(bannerSize)
        
        PAGBannerAd.loadAd(slotId, request, object : PAGBannerAdLoadListener {
            override fun onError(code: Int, message: String?) {
                channel.invokeMethod("onBannerAdLoadFailed", mapOf(
                    "code" to code,
                    "message" to (message ?: "Unknown error")
                ))
            }

            override fun onAdLoaded(ad: PAGBannerAd?) {
                bannerAd = ad
                ad?.let {
                    it.setAdInteractionListener(object : PAGBannerAdInteractionListener {
                        override fun onAdShowed() {
                        }

                        override fun onAdClicked() {
                            channel.invokeMethod("onBannerAdClicked", null)
                        }

                        override fun onAdDismissed() {
                        }
                    })
                    
                    container.removeAllViews()
                    container.addView(it.bannerView)
                    channel.invokeMethod("onBannerAdLoaded", null)
                }
            }
        })
    }

    override fun getView(): View {
        return container
    }

    override fun dispose() {
        bannerAd?.destroy()
    }
}
