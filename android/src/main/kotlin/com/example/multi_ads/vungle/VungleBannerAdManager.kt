package com.example.multi_ads.vungle

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import io.flutter.plugin.common.MethodChannel
import com.vungle.ads.BannerAdListener
import com.vungle.ads.BaseAd
import com.vungle.ads.VungleAdSize
import com.vungle.ads.VungleBannerView
import com.vungle.ads.VungleError

class VungleBannerAdManager(
    private val context: Context,
    private val activity: Activity?,
    private val listenerId: String,
    private val placementId: String,
    private val bannerSize: Int,
    private val channel: MethodChannel
) : BannerAdListener {

    companion object {
        const val TAG = "VungleBannerAd"
    }

    private var bannerView: VungleBannerView? = null

    private fun getVungleAdSize(): VungleAdSize {
        return when (bannerSize) {
            0 -> VungleAdSize.BANNER // 320x50
            1 -> VungleAdSize.BANNER_SHORT // 300x50
            2 -> VungleAdSize.BANNER_LEADERBOARD // 728x90
            3 -> VungleAdSize.MREC // 300x250
            else -> VungleAdSize.BANNER
        }
    }

    fun loadAd() {
        Log.d(TAG, "Loading banner ad - listenerId: $listenerId, placementId: $placementId, size: $bannerSize")
        
        bannerView = VungleBannerView(context, placementId, getVungleAdSize()).apply {
            adListener = this@VungleBannerAdManager
            load()
        }
    }

    fun getBannerView(): View? {
        return bannerView
    }

    fun dispose() {
        Log.d(TAG, "Disposing banner ad - listenerId: $listenerId")
        bannerView?.finishAd()
        bannerView?.adListener = null
        bannerView = null
    }

    private fun sendCallback(methodName: String, additionalData: Map<String, Any?> = emptyMap()) {
        activity?.runOnUiThread {
            val args = mutableMapOf<String, Any?>(
                "listenerId" to listenerId
            )
            args.putAll(additionalData)
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
        sendCallback("onBannerAdImpression")
    }

    override fun onAdEnd(baseAd: BaseAd) {
        Log.d(TAG, "onAdEnd - listenerId: $listenerId")
        sendCallback("onBannerAdClosed")
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
        sendCallback("onBannerAdLoadFailed", mapOf(
            "error" to mapOf("code" to adError.code, "message" to adError.localizedMessage)
        ))
    }
}
