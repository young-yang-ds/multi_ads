package com.example.multi_ads.pangle_global

import android.app.Activity
import com.bytedance.sdk.openadsdk.api.open.PAGAppOpenAd
import com.bytedance.sdk.openadsdk.api.open.PAGAppOpenAdLoadListener
import com.bytedance.sdk.openadsdk.api.open.PAGAppOpenAdInteractionListener
import com.bytedance.sdk.openadsdk.api.open.PAGAppOpenRequest
import io.flutter.plugin.common.EventChannel

class SplashAdManager(
    private val activity: Activity,
    private val slotId: String,
    private val timeout: Int,
    private val eventSink: EventChannel.EventSink?
) {
    private var appOpenAd: PAGAppOpenAd? = null

    fun loadAd() {
        val request = PAGAppOpenRequest()
        
        PAGAppOpenAd.loadAd(slotId, request, object : PAGAppOpenAdLoadListener {
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

            override fun onAdLoaded(ad: PAGAppOpenAd?) {
                appOpenAd = ad
                activity.runOnUiThread {
                    eventSink?.success(mapOf("event" to "onAdLoaded"))
                    showAd()
                }
            }
        })
    }

    private fun showAd() {
        appOpenAd?.let { ad ->
            ad.setAdInteractionListener(object : PAGAppOpenAdInteractionListener {
                override fun onAdShowed() {
                }

                override fun onAdClicked() {
                    eventSink?.success(mapOf("event" to "onAdClicked"))
                }

                override fun onAdDismissed() {
                    eventSink?.success(mapOf("event" to "onAdDismissed"))
                }
            })
            
            ad.show(activity)
        }
    }
}
