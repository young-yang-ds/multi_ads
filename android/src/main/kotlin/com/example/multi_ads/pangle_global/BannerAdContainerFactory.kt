package com.example.multi_ads.pangle_global

import android.content.Context
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class BannerAdContainerFactory(
    private val handler: PangleAdsHandler
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val creationParams = args as? Map<String, Any>
        return BannerAdContainerView(context, handler, creationParams)
    }
}

class BannerAdContainerView(
    private val context: Context,
    private val handler: PangleAdsHandler,
    creationParams: Map<String, Any>?
) : PlatformView {
    
    private val container: FrameLayout = FrameLayout(context)
    private var listenerId: String? = null
    
    init {
        listenerId = creationParams?.get("listenerId") as? String
        listenerId?.let { id ->
            displayBannerAd(id)
        }
    }
    
    private fun displayBannerAd(listenerId: String) {
        val bannerView = handler.getBannerView(listenerId) ?: return
        
        // Remove from any existing parent
        (bannerView.parent as? ViewGroup)?.removeView(bannerView)
        
        // Add to container
        container.removeAllViews()
        container.addView(bannerView, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
    }
    
    override fun getView(): View {
        return container
    }
    
    override fun dispose() {
        container.removeAllViews()
    }
}
