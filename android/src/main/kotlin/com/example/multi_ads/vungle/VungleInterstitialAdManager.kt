package com.example.multi_ads.vungle

import android.app.Activity
import android.util.Log
import io.flutter.plugin.common.EventChannel
import com.vungle.ads.AdConfig
import com.vungle.ads.BaseAd
import com.vungle.ads.InterstitialAd
import com.vungle.ads.InterstitialAdListener
import com.vungle.ads.VungleError

class VungleInterstitialAdManager(
    private val activity: Activity,
    private val placementId: String,
    private val eventSink: EventChannel.EventSink?
) : InterstitialAdListener {

    companion object {
        const val TAG = "VungleInterstitialAd"
    }

    private var interstitialAd: InterstitialAd? = null

    fun loadAd() {
        Log.d(TAG, "Loading interstitial ad for placement: $placementId")
        
        interstitialAd = InterstitialAd(activity, placementId, AdConfig().apply {
            adOrientation = AdConfig.AUTO_ROTATE
        }).apply {
            adListener = this@VungleInterstitialAdManager
            load()
        }
    }

    fun showAd() {
        Log.d(TAG, "Showing interstitial ad for placement: $placementId")
        if (interstitialAd?.canPlayAd() == true) {
            interstitialAd?.play(activity)
        } else {
            Log.w(TAG, "Interstitial ad cannot be played")
            sendEvent("onAdFailedToPlay", mapOf(
                "error" to mapOf("code" to -1, "message" to "Ad cannot be played")
            ))
        }
    }

    fun canPlayAd(): Boolean {
        return interstitialAd?.canPlayAd() ?: false
    }

    fun dispose() {
        interstitialAd?.adListener = null
        interstitialAd = null
    }

    private fun sendEvent(eventType: String, additionalData: Map<String, Any?> = emptyMap()) {
        activity.runOnUiThread {
            val eventData = mutableMapOf<String, Any?>(
                "event" to eventType,
                "placementId" to placementId
            )
            eventData.putAll(additionalData)
            eventSink?.success(eventData)
        }
    }

    // InterstitialAdListener callbacks
    override fun onAdLoaded(baseAd: BaseAd) {
        Log.d(TAG, "onAdLoaded: $placementId")
        sendEvent("onAdLoaded")
    }

    override fun onAdStart(baseAd: BaseAd) {
        Log.d(TAG, "onAdStart: $placementId")
        sendEvent("onAdShowed")
    }

    override fun onAdImpression(baseAd: BaseAd) {
        Log.d(TAG, "onAdImpression: $placementId")
        sendEvent("onAdImpression")
    }

    override fun onAdEnd(baseAd: BaseAd) {
        Log.d(TAG, "onAdEnd: $placementId")
        sendEvent("onAdDismissed")
    }

    override fun onAdClicked(baseAd: BaseAd) {
        Log.d(TAG, "onAdClicked: $placementId")
        sendEvent("onAdClicked")
    }

    override fun onAdLeftApplication(baseAd: BaseAd) {
        Log.d(TAG, "onAdLeftApplication: $placementId")
    }

    override fun onAdFailedToLoad(baseAd: BaseAd, adError: VungleError) {
        Log.e(TAG, "onAdFailedToLoad: $placementId, error: ${adError.localizedMessage}")
        sendEvent("onAdLoadFailed", mapOf(
            "error" to mapOf("code" to adError.code, "message" to adError.localizedMessage)
        ))
    }

    override fun onAdFailedToPlay(baseAd: BaseAd, adError: VungleError) {
        Log.e(TAG, "onAdFailedToPlay: $placementId, error: ${adError.localizedMessage}")
        sendEvent("onAdFailedToPlay", mapOf(
            "error" to mapOf("code" to adError.code, "message" to adError.localizedMessage)
        ))
    }
}
