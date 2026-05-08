import Flutter
import UIKit
import VungleAdsSDK

public class VungleAdsHandler: NSObject {
    var interstitialEventSink: FlutterEventSink?
    var appOpenEventSink: FlutterEventSink?
    var nativeEventSink: FlutterEventSink?
    
    private var interstitialAdManagers: [String: VungleInterstitialAdManager] = [:]
    private var appOpenAdManagers: [String: VungleAppOpenAdManager] = [:]
    private var bannerAdManagers: [String: VungleBannerAdManager] = [:]
    private var nativeAdManagers: [String: VungleNativeAdManager] = [:]
    private var channel: FlutterMethodChannel?
    
    public func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "multi_ads/vungle", binaryMessenger: registrar.messenger())
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        
        let interstitialEventChannel = FlutterEventChannel(name: "multi_ads/vungle/interstitial_events", binaryMessenger: registrar.messenger())
        interstitialEventChannel.setStreamHandler(VungleInterstitialEventStreamHandler(handler: self))
        
        let appOpenEventChannel = FlutterEventChannel(name: "multi_ads/vungle/appopen_events", binaryMessenger: registrar.messenger())
        appOpenEventChannel.setStreamHandler(VungleAppOpenEventStreamHandler(handler: self))
        
        let nativeEventChannel = FlutterEventChannel(name: "multi_ads/vungle/native_events", binaryMessenger: registrar.messenger())
        nativeEventChannel.setStreamHandler(VungleNativeEventStreamHandler(handler: self))
        
        // Register platform views
        registrar.register(VungleBannerAdViewFactory(messenger: registrar.messenger(), handler: self), withId: "multi_ads/vungle/banner")
        registrar.register(VungleBannerAdContainerFactory(handler: self), withId: "multi_ads/vungle/banner_container")
        registrar.register(VungleNativeAdViewFactory(handler: self), withId: "multi_ads/vungle/native")
    }
    
    func getBannerView(listenerId: String) -> UIView? {
        return bannerAdManagers[listenerId]?.getBannerView()
    }
    
    func getNativeAd(listenerId: String) -> VungleNative? {
        return nativeAdManagers[listenerId]?.getNativeAd()
    }
    
    func updateNativeEventSink(_ sink: FlutterEventSink?) {
        self.nativeEventSink = sink
        for manager in nativeAdManagers.values {
            manager.updateEventSink(sink)
        }
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            guard let args = call.arguments as? [String: Any],
                  let appId = args["appId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            let debug = args["debug"] as? Bool ?? false
            initialize(appId: appId, debug: debug, result: result)
            
        case "isInitialized":
            result(VungleAds.isInitialized())
            
        case "loadInterstitialAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadInterstitialAd(placementId: placementId, result: result)
            
        case "showInterstitialAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            showInterstitialAd(placementId: placementId, result: result)
            
        case "canPlayInterstitialAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            canPlayInterstitialAd(placementId: placementId, result: result)
            
        case "loadAppOpenAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadAppOpenAd(placementId: placementId, result: result)
            
        case "showAppOpenAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            showAppOpenAd(placementId: placementId, result: result)
            
        case "canPlayAppOpenAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            canPlayAppOpenAd(placementId: placementId, result: result)
            
        case "loadBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String,
                  let bannerSize = args["bannerSize"] as? Int,
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadBannerAd(placementId: placementId, bannerSize: bannerSize, listenerId: listenerId, result: result)
            
        case "disposeBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            disposeBannerAd(listenerId: listenerId, result: result)
            
        case "loadNativeAd":
            guard let args = call.arguments as? [String: Any],
                  let placementId = args["placementId"] as? String,
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadNativeAd(placementId: placementId, listenerId: listenerId, result: result)
            
        case "disposeNativeAd":
            guard let args = call.arguments as? [String: Any],
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            disposeNativeAd(listenerId: listenerId, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func initialize(appId: String, debug: Bool, result: @escaping FlutterResult) {
        print("[VungleAdsHandler] Initializing SDK with appId: \(appId)")
        
        VungleAds.initWithAppId(appId) { error in
            if let error = error {
                print("[VungleAdsHandler] SDK initialization failed: \(error.localizedDescription)")
                result(false)
            } else {
                print("[VungleAdsHandler] SDK initialized successfully")
                result(true)
            }
        }
    }
    
    private func loadInterstitialAd(placementId: String, result: @escaping FlutterResult) {
        // Dispose existing ad
        interstitialAdManagers[placementId]?.dispose()
        
        let manager = VungleInterstitialAdManager(placementId: placementId, eventSink: interstitialEventSink)
        interstitialAdManagers[placementId] = manager
        manager.loadAd()
        result(true)
    }
    
    private func showInterstitialAd(placementId: String, result: @escaping FlutterResult) {
        guard let manager = interstitialAdManagers[placementId] else {
            result(FlutterError(code: "NO_AD", message: "Interstitial ad not found", details: nil))
            return
        }
        manager.showAd()
        result(nil)
    }
    
    private func canPlayInterstitialAd(placementId: String, result: @escaping FlutterResult) {
        let manager = interstitialAdManagers[placementId]
        result(manager?.canPlayAd() ?? false)
    }
    
    private func loadAppOpenAd(placementId: String, result: @escaping FlutterResult) {
        // Dispose existing ad
        appOpenAdManagers[placementId]?.dispose()
        
        let manager = VungleAppOpenAdManager(placementId: placementId, eventSink: appOpenEventSink)
        appOpenAdManagers[placementId] = manager
        manager.loadAd()
        result(true)
    }
    
    private func showAppOpenAd(placementId: String, result: @escaping FlutterResult) {
        guard let manager = appOpenAdManagers[placementId] else {
            result(FlutterError(code: "NO_AD", message: "App open ad not found", details: nil))
            return
        }
        manager.showAd()
        result(nil)
    }
    
    private func canPlayAppOpenAd(placementId: String, result: @escaping FlutterResult) {
        let manager = appOpenAdManagers[placementId]
        result(manager?.canPlayAd() ?? false)
    }
    
    private func loadBannerAd(placementId: String, bannerSize: Int, listenerId: String, result: @escaping FlutterResult) {
        guard let channel = self.channel else {
            result(FlutterError(code: "NO_CHANNEL", message: "Method channel not available", details: nil))
            return
        }
        
        // Dispose existing banner
        bannerAdManagers[listenerId]?.dispose()
        
        let manager = VungleBannerAdManager(listenerId: listenerId, placementId: placementId, bannerSize: bannerSize, channel: channel)
        bannerAdManagers[listenerId] = manager
        manager.loadAd()
        result(true)
    }
    
    private func disposeBannerAd(listenerId: String, result: @escaping FlutterResult) {
        bannerAdManagers[listenerId]?.dispose()
        bannerAdManagers.removeValue(forKey: listenerId)
        result(nil)
    }
    
    private func loadNativeAd(placementId: String, listenerId: String, result: @escaping FlutterResult) {
        if let existing = nativeAdManagers[listenerId] {
            existing.dispose()
        }
        let manager = VungleNativeAdManager(listenerId: listenerId, placementId: placementId, eventSink: nativeEventSink)
        nativeAdManagers[listenerId] = manager
        manager.loadAd()
        result(true)
    }
    
    private func disposeNativeAd(listenerId: String, result: @escaping FlutterResult) {
        nativeAdManagers[listenerId]?.dispose()
        nativeAdManagers.removeValue(forKey: listenerId)
        result(nil)
    }
}

// MARK: - Event Stream Handlers

class VungleInterstitialEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: VungleAdsHandler?
    
    init(handler: VungleAdsHandler) {
        self.handler = handler
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler?.interstitialEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler?.interstitialEventSink = nil
        return nil
    }
}

class VungleAppOpenEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: VungleAdsHandler?
    
    init(handler: VungleAdsHandler) {
        self.handler = handler
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler?.appOpenEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler?.appOpenEventSink = nil
        return nil
    }
}

class VungleNativeEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: VungleAdsHandler?
    
    init(handler: VungleAdsHandler) {
        self.handler = handler
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler?.updateNativeEventSink(events)
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler?.updateNativeEventSink(nil)
        return nil
    }
}
