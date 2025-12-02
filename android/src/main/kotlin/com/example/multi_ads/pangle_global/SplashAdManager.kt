package com.example.multi_ads.pangle_global

import android.app.Activity
import android.view.ViewGroup
import com.bytedance.sdk.openadsdk.api.splash.PAGSplashAd
import com.bytedance.sdk.openadsdk.api.splash.PAGSplashRequest
import com.bytedance.sdk.openadsdk.api.splash.PAGSplashAdLoadListener
import com.bytedance.sdk.openadsdk.api.splash.PAGSplashAdInteractionListener
import com.bytedance.sdk.openadsdk.api.PAGRequest
import io.flutter.plugin.common.EventChannel

class SplashAdManager(
    private val activity: Activity,
    private val slotId: String,
    private val timeout: Int,
    private val eventSink: EventChannel.EventSink?
) {
    private var splashAd: PAGSplashAd? = null

    fun loadAd() {
        val request = PAGRequest()
        
        PAGSplashAd.load(slotId, request, object : PAGSplashAdLoadListener {
            override fun onError(code: Int, message: String?) {
                activity.runOnUiThread {
                    eventSink?.success(mapOf(
                        "event" to "onAdLoadFailed",
                        "error" to mapOf(
                            "code" to code,
                            "message" to (message ?: "Unknown error")
                        )
                    ))
                }
            }

            override fun onAdLoaded(ad: PAGSplashAd?) {
                splashAd = ad
                activity.runOnUiThread {
                    eventSink?.success(mapOf("event" to "onAdLoaded"))
                    showAd()
                }
            }
        })
    }

    private fun showAd() {
        splashAd?.let { ad ->
            val rootView = activity.window.decorView.findViewById<ViewGroup>(android.R.id.content)
            
            ad.setAdInteractionListener(object : PAGSplashAdInteractionListener {
                override fun onAdShowed() {
                }

                override fun onAdClicked() {
                    eventSink?.success(mapOf("event" to "onAdClicked"))
                }

                override fun onAdDismissed() {
                    eventSink?.success(mapOf("event" to "onAdDismissed"))
                    rootView.removeAllViews()
                }
            })
            
            rootView.addView(ad.splashView)
        }
    }
}
