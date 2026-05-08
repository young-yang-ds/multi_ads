package com.example.multi_ads.vungle

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.EventChannel
import com.vungle.ads.NativeAd
import com.vungle.ads.NativeAdListener
import com.vungle.ads.BaseAd
import com.vungle.ads.VungleError

class VungleNativeAdManager(
    private val context: Context,
    private val activity: Activity?,
    val listenerId: String,
    private val placementId: String,
    private val style: Map<String, Any>?,
    private var eventSink: EventChannel.EventSink?
) {
    companion object {
        const val TAG = "VungleNativeAdManager"
    }

    var nativeAd: NativeAd? = null
        private set

    fun updateEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun loadAd() {
        Log.d(TAG, "Loading native ad for listener: $listenerId, placement: $placementId")

        nativeAd = NativeAd(context, placementId).apply {
            adListener = object : NativeAdListener {
                override fun onAdLoaded(baseAd: BaseAd) {
                    Log.d(TAG, "Native ad loaded for listener: $listenerId")
                    activity?.runOnUiThread {
                        eventSink?.success(mapOf(
                            "event" to "onAdLoaded",
                            "listenerId" to listenerId,
                            "placementId" to placementId
                        ))
                    }
                }

                override fun onAdFailedToLoad(baseAd: BaseAd, adError: VungleError) {
                    Log.e(TAG, "Native ad load failed for listener: $listenerId, ${adError.localizedMessage}")
                    activity?.runOnUiThread {
                        eventSink?.success(mapOf(
                            "event" to "onAdLoadFailed",
                            "listenerId" to listenerId,
                            "placementId" to placementId,
                            "error" to mapOf(
                                "code" to adError.code,
                                "message" to (adError.localizedMessage ?: "Unknown error")
                            )
                        ))
                    }
                }

                override fun onAdClicked(baseAd: BaseAd) {
                    Log.d(TAG, "Native ad clicked for listener: $listenerId")
                    activity?.runOnUiThread {
                        eventSink?.success(mapOf(
                            "event" to "onAdClicked",
                            "listenerId" to listenerId,
                            "placementId" to placementId
                        ))
                    }
                }

                override fun onAdImpression(baseAd: BaseAd) {
                    Log.d(TAG, "Native ad impression for listener: $listenerId")
                    activity?.runOnUiThread {
                        eventSink?.success(mapOf(
                            "event" to "onAdImpression",
                            "listenerId" to listenerId,
                            "placementId" to placementId
                        ))
                    }
                }

                override fun onAdStart(baseAd: BaseAd) {}
                override fun onAdEnd(baseAd: BaseAd) {}
                override fun onAdLeftApplication(baseAd: BaseAd) {}
                override fun onAdFailedToPlay(baseAd: BaseAd, adError: VungleError) {}
            }
            load()
        }
    }

    fun dispose() {
        nativeAd?.unregisterView()
        nativeAd = null
    }
}
