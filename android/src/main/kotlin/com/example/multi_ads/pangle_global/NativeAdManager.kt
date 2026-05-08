package com.example.multi_ads.pangle_global

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.EventChannel
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAd
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAdLoadListener
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeRequest

class NativeAdManager(
    private val context: Context,
    private val activity: Activity?,
    private val listenerId: String,
    private val slotId: String,
    private val style: Map<String, Any>?,
    private var eventSink: EventChannel.EventSink?
) {
    companion object {
        const val TAG = "PangleNativeAdManager"
    }

    var nativeAd: PAGNativeAd? = null
        private set

    fun updateEventSink(sink: EventChannel.EventSink?) {
        this.eventSink = sink
    }

    fun loadAd() {
        Log.d(TAG, "Loading native ad with listenerId: $listenerId, slotId: $slotId")

        val request = PAGNativeRequest()

        PAGNativeAd.loadAd(slotId, request, object : PAGNativeAdLoadListener {
            override fun onError(code: Int, message: String?) {
                Log.e(TAG, "Native ad load failed ($listenerId): $code - $message")
                activity?.runOnUiThread {
                    eventSink?.success(mapOf(
                        "listenerId" to listenerId,
                        "event" to "onAdLoadFailed",
                        "error" to mapOf(
                            "code" to code,
                            "message" to (message ?: "Unknown error")
                        )
                    ))
                }
            }

            override fun onAdLoaded(ad: PAGNativeAd?) {
                Log.d(TAG, "Native ad loaded successfully ($listenerId)")
                nativeAd = ad

                activity?.runOnUiThread {
                    eventSink?.success(mapOf(
                        "listenerId" to listenerId,
                        "event" to "onAdLoaded"
                    ))
                }
            }
        })
    }

    fun getListenerId(): String = listenerId

    fun dispose() {
        Log.d(TAG, "Disposing ad ($listenerId)")
        nativeAd = null
    }
}
