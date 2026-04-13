package com.example.multi_ads.pangle_global

import android.app.Activity
import android.content.Context
import android.util.Log
import io.flutter.plugin.common.EventChannel
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAd
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAdLoadListener
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAdInteractionListener
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeRequest

class NativeAdManager(
    private val context: Context,
    private val activity: Activity?,
    private val slotId: String,
    private val style: Map<String, Any>?,
    private val eventSink: EventChannel.EventSink?
) {
    companion object {
        const val TAG = "PangleNativeAdManager"
    }

    var nativeAd: PAGNativeAd? = null
        private set

    fun loadAd() {
        Log.d(TAG, "Loading native ad with slotId: $slotId")

        val request = PAGNativeRequest()

        PAGNativeAd.loadAd(slotId, request, object : PAGNativeAdLoadListener {
            override fun onError(code: Int, message: String?) {
                Log.e(TAG, "Native ad load failed: $code - $message")
                activity?.runOnUiThread {
                    eventSink?.success(mapOf(
                        "event" to "onAdLoadFailed",
                        "error" to mapOf(
                            "code" to code,
                            "message" to (message ?: "Unknown error")
                        )
                    ))
                }
            }

            override fun onAdLoaded(ad: PAGNativeAd?) {
                Log.d(TAG, "Native ad loaded successfully")
                nativeAd = ad

                ad?.setAdInteractionListener(object : PAGNativeAdInteractionListener {
                    override fun onAdShowed() {
                        Log.d(TAG, "Native ad showed")
                        activity?.runOnUiThread {
                            eventSink?.success(mapOf(
                                "event" to "onAdShowed"
                            ))
                        }
                    }

                    override fun onAdClicked() {
                        Log.d(TAG, "Native ad clicked")
                        activity?.runOnUiThread {
                            eventSink?.success(mapOf(
                                "event" to "onAdClicked"
                            ))
                        }
                    }

                    override fun onAdDismissed() {
                        Log.d(TAG, "Native ad dismissed")
                    }
                })

                activity?.runOnUiThread {
                    eventSink?.success(mapOf(
                        "event" to "onAdLoaded"
                    ))
                }
            }
        })
    }

    fun dispose() {
        nativeAd = null
    }
}
