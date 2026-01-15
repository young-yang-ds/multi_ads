package com.example.multi_ads.vungle

import android.app.Activity
import android.content.Context
import android.util.Log
import android.view.View
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import com.vungle.ads.InitializationListener
import com.vungle.ads.VungleAds
import com.vungle.ads.VungleError

class VungleAdsHandler(
    private val flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
) {
    companion object {
        const val TAG = "VungleAdsHandler"
    }

    private val channel: MethodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "multi_ads/vungle")
    private val interstitialEventChannel: EventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multi_ads/vungle/interstitial_events")
    private val appOpenEventChannel: EventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "multi_ads/vungle/appopen_events")

    private val context: Context = flutterPluginBinding.applicationContext
    private var activity: Activity? = null

    private var interstitialEventSink: EventChannel.EventSink? = null
    private var appOpenEventSink: EventChannel.EventSink? = null

    private val interstitialAdManagers = mutableMapOf<String, VungleInterstitialAdManager>()
    private val appOpenAdManagers = mutableMapOf<String, VungleAppOpenAdManager>()
    private val bannerAdManagers = mutableMapOf<String, VungleBannerAdManager>()

    init {
        channel.setMethodCallHandler { call, result ->
            onMethodCall(call, result)
        }

        interstitialEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                interstitialEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                interstitialEventSink = null
            }
        })

        appOpenEventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                appOpenEventSink = events
            }

            override fun onCancel(arguments: Any?) {
                appOpenEventSink = null
            }
        })

        // Register platform views
        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads/vungle/banner",
            VungleBannerAdViewFactory(flutterPluginBinding.binaryMessenger, channel)
        )

        flutterPluginBinding.platformViewRegistry.registerViewFactory(
            "multi_ads/vungle/banner_container",
            VungleBannerAdContainerFactory(this)
        )
    }

    fun setActivity(activity: Activity?) {
        this.activity = activity
    }

    fun getBannerView(listenerId: String): View? {
        return bannerAdManagers[listenerId]?.getBannerView()
    }

    private fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "initialize" -> {
                val appId = call.argument<String>("appId") ?: ""
                val debug = call.argument<Boolean>("debug") ?: false
                initialize(appId, debug, result)
            }
            "isInitialized" -> {
                result.success(VungleAds.isInitialized())
            }
            "loadInterstitialAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                loadInterstitialAd(placementId, result)
            }
            "showInterstitialAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                showInterstitialAd(placementId, result)
            }
            "canPlayInterstitialAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                canPlayInterstitialAd(placementId, result)
            }
            "loadAppOpenAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                loadAppOpenAd(placementId, result)
            }
            "showAppOpenAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                showAppOpenAd(placementId, result)
            }
            "canPlayAppOpenAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                canPlayAppOpenAd(placementId, result)
            }
            "loadBannerAd" -> {
                val placementId = call.argument<String>("placementId") ?: ""
                val bannerSize = call.argument<Int>("bannerSize") ?: 0
                val listenerId = call.argument<String>("listenerId") ?: ""
                loadBannerAd(placementId, bannerSize, listenerId, result)
            }
            "disposeBannerAd" -> {
                val listenerId = call.argument<String>("listenerId") ?: ""
                disposeBannerAd(listenerId, result)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun initialize(appId: String, debug: Boolean, result: MethodChannel.Result) {
        Log.d(TAG, "Initializing Vungle SDK with appId: $appId")
        
        VungleAds.init(context, appId, object : InitializationListener {
            override fun onSuccess() {
                Log.d(TAG, "Vungle SDK initialized successfully")
                activity?.runOnUiThread {
                    result.success(true)
                }
            }

            override fun onError(vungleError: VungleError) {
                Log.e(TAG, "Vungle SDK initialization failed: ${vungleError.localizedMessage}")
                activity?.runOnUiThread {
                    result.success(false)
                }
            }
        })
    }

    private fun loadInterstitialAd(placementId: String, result: MethodChannel.Result) {
        activity?.let { act ->
            // Dispose existing ad with same placementId
            interstitialAdManagers[placementId]?.dispose()
            
            val manager = VungleInterstitialAdManager(act, placementId, interstitialEventSink)
            interstitialAdManagers[placementId] = manager
            manager.loadAd()
            result.success(true)
        } ?: result.success(false)
    }

    private fun showInterstitialAd(placementId: String, result: MethodChannel.Result) {
        val manager = interstitialAdManagers[placementId]
        if (manager == null) {
            result.error("NO_AD", "Interstitial ad not found for placement: $placementId", null)
            return
        }
        manager.showAd()
        result.success(null)
    }

    private fun canPlayInterstitialAd(placementId: String, result: MethodChannel.Result) {
        val manager = interstitialAdManagers[placementId]
        result.success(manager?.canPlayAd() ?: false)
    }

    private fun loadAppOpenAd(placementId: String, result: MethodChannel.Result) {
        activity?.let { act ->
            // Dispose existing ad with same placementId
            appOpenAdManagers[placementId]?.dispose()
            
            val manager = VungleAppOpenAdManager(act, placementId, appOpenEventSink)
            appOpenAdManagers[placementId] = manager
            manager.loadAd()
            result.success(true)
        } ?: result.success(false)
    }

    private fun showAppOpenAd(placementId: String, result: MethodChannel.Result) {
        val manager = appOpenAdManagers[placementId]
        if (manager == null) {
            result.error("NO_AD", "App open ad not found for placement: $placementId", null)
            return
        }
        manager.showAd()
        result.success(null)
    }

    private fun canPlayAppOpenAd(placementId: String, result: MethodChannel.Result) {
        val manager = appOpenAdManagers[placementId]
        result.success(manager?.canPlayAd() ?: false)
    }

    private fun loadBannerAd(placementId: String, bannerSize: Int, listenerId: String, result: MethodChannel.Result) {
        // Dispose existing banner with same listenerId
        bannerAdManagers[listenerId]?.dispose()

        val manager = VungleBannerAdManager(context, activity, listenerId, placementId, bannerSize, channel)
        bannerAdManagers[listenerId] = manager
        manager.loadAd()

        result.success(true)
    }

    private fun disposeBannerAd(listenerId: String, result: MethodChannel.Result) {
        val manager = bannerAdManagers[listenerId]
        manager?.dispose()
        bannerAdManagers.remove(listenerId)
        result.success(null)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        interstitialEventChannel.setStreamHandler(null)
        appOpenEventChannel.setStreamHandler(null)
        
        // Dispose all ad managers
        interstitialAdManagers.values.forEach { it.dispose() }
        interstitialAdManagers.clear()
        
        appOpenAdManagers.values.forEach { it.dispose() }
        appOpenAdManagers.clear()
        
        bannerAdManagers.values.forEach { it.dispose() }
        bannerAdManagers.clear()
    }
}
