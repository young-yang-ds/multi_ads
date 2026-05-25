package com.example.multi_ads.pangle_global

import android.app.Activity
import android.content.Context
import android.view.View
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.bytedance.sdk.openadsdk.api.init.PAGConfig
import com.bytedance.sdk.openadsdk.api.init.PAGSdk
import com.bytedance.sdk.openadsdk.api.nativeAd.PAGNativeAd

class PangleAdsHandler(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) {
    private val channel: MethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "multi_ads/pangle_global")
    private val splashEventChannel: EventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multi_ads/pangle_global/splash_events")
    private val interstitialEventChannel: EventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multi_ads/pangle_global/interstitial_events")
    
    private val context: Context = flutterPluginBinding.applicationContext
    private var activity: Activity? = null
    
    private val nativeEventChannel: EventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multi_ads/pangle_global/native_events")

    private var splashEventSink: EventChannel.EventSink? = null
    private var interstitialEventSink: EventChannel.EventSink? = null
    private var nativeEventSink: EventChannel.EventSink? = null
    
    private var splashAdManager: SplashAdManager? = null
    private var interstitialAdManager: InterstitialAdManager? = null
    private val bannerAdManagers = mutableMapOf<String, BannerAdManager>()
    private val nativeAdManagers = mutableMapOf<String, NativeAdManager>()

    init {
        channel.setMethodCallHandler { call, result ->
            onMethodCall(call, result)
        }
        
        splashEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                splashEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                splashEventSink = null
            }
        })
        
        interstitialEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                interstitialEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                interstitialEventSink = null
            }
        })
        
        nativeEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                nativeEventSink = events
                for (mgr in nativeAdManagers.values) {
                    mgr.updateEventSink(events)
                }
            }

            override fun onCancel(arguments: Any?) {
                nativeEventSink = null
                for (mgr in nativeAdManagers.values) {
                    mgr.updateEventSink(null)
                }
            }
        })
        
        // Register platform views
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads/pangle_global/banner",
            BannerAdViewFactory(flutterPluginBinding.binaryMessenger)
        )
        
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads/pangle_global/banner_container",
            BannerAdContainerFactory(this)
        )
        
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads/pangle_global/native",
            NativeAdViewFactory(this)
        )
    }
    
    fun setActivity(activity: Activity?) {
        this.activity = activity
    }
    
    fun getBannerView(listenerId: String): View? {
        return bannerAdManagers[listenerId]?.getBannerView()
    }
    
    fun getNativeAd(listenerId: String): PAGNativeAd? {
        return nativeAdManagers[listenerId]?.nativeAd
    }
    
    fun getNativeEventSink(): EventChannel.EventSink? {
        return nativeEventSink
    }

    fun sendNativeSwipe(listenerId: String, direction: Int) {
        nativeEventSink?.success(mapOf(
            "listenerId" to listenerId,
            "event" to "onAdSwipe",
            "direction" to direction
        ))
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val appId = call.argument<String>("appId") ?: ""
                val debug = call.argument<Boolean>("debug") ?: false
                initialize(appId, debug, result)
            }
            "loadSplashAd" -> {
                val slotId = call.argument<String>("slotId") ?: ""
                val timeout = call.argument<Int>("timeout") ?: 3000
                loadSplashAd(slotId, timeout, result)
            }
            "loadInterstitialAd" -> {
                val slotId = call.argument<String>("slotId") ?: ""
                loadInterstitialAd(slotId, result)
            }
            "showInterstitialAd" -> {
                showInterstitialAd(result)
            }
            "loadBannerAd" -> {
                val slotId = call.argument<String>("slotId") ?: ""
                val adSize = call.argument<Int>("adSize") ?: 0
                val listenerId = call.argument<String>("listenerId") ?: ""
                loadBannerAd(slotId, adSize, listenerId, result)
            }
            "showBannerAd" -> {
                val listenerId = call.argument<String>("listenerId") ?: ""
                showBannerAd(listenerId, result)
            }
            "hideBannerAd" -> {
                val listenerId = call.argument<String>("listenerId") ?: ""
                hideBannerAd(listenerId, result)
            }
            "disposeBannerAd" -> {
                val listenerId = call.argument<String>("listenerId") ?: ""
                disposeBannerAd(listenerId, result)
            }
            "loadNativeAd" -> {
                val slotId = call.argument<String>("slotId") ?: ""
                val listenerId = call.argument<String>("listenerId") ?: ""
                @Suppress("UNCHECKED_CAST")
                val style = call.argument<Map<String, Any>>("style")
                loadNativeAd(slotId, listenerId, style, result)
            }
            "disposeNativeAd" -> {
                val listenerId = call.argument<String>("listenerId") ?: ""
                disposeNativeAd(listenerId, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(appId: String, debug: Boolean, result: MethodChannel.Result) {
        // Note: PAGConfig.Builder.setGDPRConsent has been removed since Pangle SDK 7.9.0.9.
        val config = PAGConfig.Builder()
            .appId(appId)
            .debugLog(debug)
            .setPAConsent(1)
            .build()
        
        PAGSdk.init(context, config, object : PAGSdk.PAGInitCallback {
            override fun success() {
                activity?.runOnUiThread {
                    result.success(true)
                }
            }

            override fun fail(code: Int, msg: String?) {
                activity?.runOnUiThread {
                    result.success(false)
                }
            }
        })
    }

    private fun loadSplashAd(slotId: String, timeout: Int, result: MethodChannel.Result) {
        activity?.let { act ->
            splashAdManager = SplashAdManager(act, slotId, timeout, splashEventSink)
            splashAdManager?.loadAd()
            result.success(null)
        } ?: result.error("NO_ACTIVITY", "Activity is null", null)
    }

    private fun loadInterstitialAd(slotId: String, result: MethodChannel.Result) {
        activity?.let { act ->
            interstitialAdManager = InterstitialAdManager(act, slotId, interstitialEventSink)
            interstitialAdManager?.loadAd()
            result.success(true)
        } ?: result.success(false)
    }

    private fun showInterstitialAd(result: MethodChannel.Result) {
        interstitialAdManager?.showAd()
        result.success(null)
    }

    private fun loadBannerAd(slotId: String, adSize: Int, listenerId: String, result: MethodChannel.Result) {
        // Dispose existing banner with same listenerId
        bannerAdManagers[listenerId]?.dispose()
        
        val bannerAdManager = BannerAdManager(context, activity, listenerId, slotId, adSize, channel)
        bannerAdManagers[listenerId] = bannerAdManager
        bannerAdManager.loadAd()
        
        result.success(true)
    }
    
    private fun showBannerAd(listenerId: String, result: MethodChannel.Result) {
        val bannerAdManager = bannerAdManagers[listenerId]
        if (bannerAdManager == null) {
            result.error("NO_BANNER", "Banner ad not found", null)
            return
        }
        
        val success = bannerAdManager.showAd()
        result.success(success)
    }
    
    private fun hideBannerAd(listenerId: String, result: MethodChannel.Result) {
        val bannerAdManager = bannerAdManagers[listenerId]
        if (bannerAdManager == null) {
            result.error("NO_BANNER", "Banner ad not found", null)
            return
        }
        
        bannerAdManager.hideAd()
        result.success(null)
    }
    
    private fun disposeBannerAd(listenerId: String, result: MethodChannel.Result) {
        val bannerAdManager = bannerAdManagers[listenerId]
        bannerAdManager?.dispose()
        bannerAdManagers.remove(listenerId)
        result.success(null)
    }
    
    private fun loadNativeAd(slotId: String, listenerId: String, style: Map<String, Any>?, result: MethodChannel.Result) {
        // Dispose existing manager with the same listenerId (if any)
        nativeAdManagers[listenerId]?.dispose()
        val manager = NativeAdManager(context, activity, listenerId, slotId, style, nativeEventSink)
        nativeAdManagers[listenerId] = manager
        manager.loadAd()
        result.success(true)
    }
    
    private fun disposeNativeAd(listenerId: String, result: MethodChannel.Result) {
        nativeAdManagers[listenerId]?.dispose()
        nativeAdManagers.remove(listenerId)
        result.success(null)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        splashEventChannel.setStreamHandler(null)
        interstitialEventChannel.setStreamHandler(null)
        nativeEventChannel.setStreamHandler(null)
    }
}
