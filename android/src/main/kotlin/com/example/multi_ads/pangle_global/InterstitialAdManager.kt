package com.example.multi_ads.pangle_global

import android.app.Activity
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAd
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAdLoadListener
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialAdInteractionListener
import com.bytedance.sdk.openadsdk.api.interstitial.PAGInterstitialRequest
import io.flutter.plugin.common.EventChannel

class InterstitialAdManager(
    private val activity: Activity,
    private val slotId: String,
    private val eventSink: EventChannel.EventSink?
) {
    private var interstitialAd: PAGInterstitialAd? = null

    fun loadAd() {
        val request = PAGInterstitialRequest()
        
        PAGInterstitialAd.loadAd(slotId, request, object : PAGInterstitialAdLoadListener {
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

            override fun onAdLoaded(ad: PAGInterstitialAd?) {
                interstitialAd = ad
                activity.runOnUiThread {
                    eventSink?.success(mapOf("event" to "onAdLoaded"))
                }
            }
        })
    }

    fun showAd() {
        interstitialAd?.let { ad ->
            ad.setAdInteractionListener(object : PAGInterstitialAdInteractionListener {
                override fun onAdShowed() {
                    eventSink?.success(mapOf("event" to "onAdShowed"))
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
