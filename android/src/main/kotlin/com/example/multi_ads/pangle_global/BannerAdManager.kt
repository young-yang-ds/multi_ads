package com.example.multi_ads.pangle_global

import android.app.Activity
import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.plugin.common.MethodChannel
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAd
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAdLoadListener
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerAdInteractionListener
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerRequest
import com.bytedance.sdk.openadsdk.api.banner.PAGBannerSize

class BannerAdManager(
    private val context: Context,
    private val activity: Activity?,
    private val listenerId: String,
    private val slotId: String,
    private val adSizeIndex: Int,
    private val channel: MethodChannel
) {
    private var bannerAd: PAGBannerAd? = null
    private var bannerSize: PAGBannerSize? = null
    
    val isLoaded: Boolean
        get() = bannerAd != null
    
    fun loadAd() {
        bannerSize = when (adSizeIndex) {
            0 -> PAGBannerSize.BANNER_W_320_H_50
            1 -> PAGBannerSize.BANNER_W_300_H_250
            2 -> PAGBannerSize.BANNER_W_728_H_90
            3 -> {
                val screenWidth = context.resources.displayMetrics.widthPixels
                val density = context.resources.displayMetrics.density
                val widthDp = (screenWidth / density).toInt()
                PAGBannerSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(context, widthDp)
            }
            else -> PAGBannerSize.BANNER_W_320_H_50
        }
        
        val request = PAGBannerRequest(bannerSize)
        
        PAGBannerAd.loadAd(slotId, request, object : PAGBannerAdLoadListener {
            override fun onError(code: Int, message: String?) {
                activity?.runOnUiThread {
                    channel.invokeMethod("onBannerAdLoadFailed", mapOf(
                        "listenerId" to listenerId,
                        "error" to mapOf(
                            "code" to code,
                            "message" to (message ?: "Unknown error")
                        )
                    ))
                }
            }

            override fun onAdLoaded(ad: PAGBannerAd?) {
                bannerAd = ad
                ad?.setAdInteractionListener(object : PAGBannerAdInteractionListener {
                    override fun onAdShowed() {
                        activity?.runOnUiThread {
                            channel.invokeMethod("onBannerAdShowed", mapOf(
                                "listenerId" to listenerId
                            ))
                        }
                    }

                    override fun onAdClicked() {
                        activity?.runOnUiThread {
                            channel.invokeMethod("onBannerAdClicked", mapOf(
                                "listenerId" to listenerId
                            ))
                        }
                    }

                    override fun onAdDismissed() {
                        activity?.runOnUiThread {
                            channel.invokeMethod("onBannerAdDismissed", mapOf(
                                "listenerId" to listenerId
                            ))
                        }
                    }
                })
                
                activity?.runOnUiThread {
                    channel.invokeMethod("onBannerAdLoaded", mapOf(
                        "listenerId" to listenerId
                    ))
                }
            }
        })
    }
    
    fun getBannerView(): View? {
        return bannerAd?.bannerView
    }
    
    fun showAd(): Boolean {
        val ad = bannerAd ?: return false
        val act = activity ?: return false
        
        // Remove from any existing parent
        val bannerView = ad.bannerView
        (bannerView.parent as? ViewGroup)?.removeView(bannerView)
        
        // Add to root view at bottom
        val rootView = act.window.decorView.findViewById<ViewGroup>(android.R.id.content)
        val params = FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.WRAP_CONTENT,
            FrameLayout.LayoutParams.WRAP_CONTENT
        ).apply {
            gravity = android.view.Gravity.BOTTOM or android.view.Gravity.CENTER_HORIZONTAL
            bottomMargin = 30
        }
        rootView.addView(bannerView, params)
        
        return true
    }
    
    fun hideAd() {
        val bannerView = bannerAd?.bannerView ?: return
        (bannerView.parent as? ViewGroup)?.removeView(bannerView)
    }
    
    fun dispose() {
        hideAd()
        bannerAd?.destroy()
        bannerAd = null
    }
}
