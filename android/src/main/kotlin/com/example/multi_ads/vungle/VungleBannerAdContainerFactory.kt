package com.example.multi_ads.vungle

import android.content.Context
import android.util.Log
import android.view.View
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class VungleBannerAdContainerFactory(
    private val handler: VungleAdsHandler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as Map<String, Any?>
        return VungleBannerAdContainerView(context, viewId, creationParams, handler)
    }
}

class VungleBannerAdContainerView(
    private val context: Context,
    private val viewId: Int,
    private val creationParams: Map<String, Any?>,
    private val handler: VungleAdsHandler
) : PlatformView {

    companion object {
        const val TAG = "VungleBannerContainer"
    }

    private val containerView: FrameLayout = FrameLayout(context)

    init {
        val listenerId = creationParams["listenerId"] as? String ?: ""
        Log.d(TAG, "Creating banner container for listenerId: $listenerId")

        val bannerView = handler.getBannerView(listenerId)
        if (bannerView != null) {
            // Remove from previous parent if exists
            (bannerView.parent as? FrameLayout)?.removeView(bannerView)
            containerView.addView(bannerView)
            Log.d(TAG, "Banner view added to container")
        } else {
            Log.w(TAG, "Banner view not found for listenerId: $listenerId")
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {
        Log.d(TAG, "Disposing banner container")
        containerView.removeAllViews()
    }
}
