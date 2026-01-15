package com.example.multi_ads.vungle

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import com.vungle.ads.BannerAdListener
import com.vungle.ads.BaseAd
import com.vungle.ads.VungleAdSize
import com.vungle.ads.VungleBannerView
import com.vungle.ads.VungleError

class VungleBannerAdViewFactory(
    private val messenger: BinaryMessenger,
    private val channel: MethodChannel
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String, Any?>
        return VungleBannerAdPlatformView(context, viewId, creationParams, channel)
    }
}

class VungleBannerAdPlatformView(
    private val context: Context,
    private val viewId: Int,
    private val creationParams: Map<String, Any?>,
    private val channel: MethodChannel
) : PlatformView, BannerAdListener {

    companion object {
        const val TAG = "VungleBannerView"
    }

    private val containerView: FrameLayout = FrameLayout(context)
    private var bannerView: VungleBannerView? = null
    private val listenerId: String = creationParams["listenerId"] as? String ?: ""
    private val mainHandler = Handler(Looper.getMainLooper())

    init {
        val placementId = creationParams["placementId"] as? String ?: ""
        val bannerSize = creationParams["bannerSize"] as? Int ?: 0

        Log.d(TAG, "Creating banner view - placementId: $placementId, size: $bannerSize, listenerId: $listenerId")

        val vungleAdSize = when (bannerSize) {
            0 -> VungleAdSize.BANNER
            1 -> VungleAdSize.BANNER_SHORT
            2 -> VungleAdSize.BANNER_LEADERBOARD
            3 -> VungleAdSize.MREC
            else -> VungleAdSize.BANNER
        }

        bannerView = VungleBannerView(context, placementId, vungleAdSize).apply {
            adListener = this@VungleBannerAdPlatformView
            load()
        }

        containerView.addView(bannerView)
    }

    override fun getView(): View = containerView

    override fun dispose() {
        Log.d(TAG, "Disposing banner view - listenerId: $listenerId")
        bannerView?.finishAd()
        bannerView?.adListener = null
        containerView.removeAllViews()
        bannerView = null
    }

    private fun sendCallback(methodName: String, additionalData: Map<String, Any?> = emptyMap()) {
        mainHandler.post {
            val args = mutableMapOf<String, Any?>(
                "listenerId" to listenerId
            )
            args.putAll(additionalData)
            Log.d(TAG, "Sending callback: $methodName with listenerId: $listenerId")
            channel.invokeMethod(methodName, args)
        }
    }

    // BannerAdListener callbacks
    override fun onAdLoaded(baseAd: BaseAd) {
        Log.d(TAG, "onAdLoaded - listenerId: $listenerId")
        sendCallback("onBannerAdLoaded")
    }

    override fun onAdStart(baseAd: BaseAd) {
        Log.d(TAG, "onAdStart - listenerId: $listenerId")
        sendCallback("onBannerAdShowed")
    }

    override fun onAdImpression(baseAd: BaseAd) {
        Log.d(TAG, "onAdImpression - listenerId: $listenerId")
    }

    override fun onAdEnd(baseAd: BaseAd) {
        Log.d(TAG, "onAdEnd - listenerId: $listenerId")
    }

    override fun onAdClicked(baseAd: BaseAd) {
        Log.d(TAG, "onAdClicked - listenerId: $listenerId")
        sendCallback("onBannerAdClicked")
    }

    override fun onAdLeftApplication(baseAd: BaseAd) {
        Log.d(TAG, "onAdLeftApplication - listenerId: $listenerId")
    }

    override fun onAdFailedToLoad(baseAd: BaseAd, adError: VungleError) {
        Log.e(TAG, "onAdFailedToLoad - listenerId: $listenerId, error: ${adError.localizedMessage}")
        sendCallback("onBannerAdLoadFailed", mapOf(
            "error" to mapOf("code" to adError.code, "message" to adError.localizedMessage)
        ))
    }

    override fun onAdFailedToPlay(baseAd: BaseAd, adError: VungleError) {
        Log.e(TAG, "onAdFailedToPlay - listenerId: $listenerId, error: ${adError.localizedMessage}")
    }
}

