import Flutter
import UIKit
import PAGAdSDK

public class PangleAdsHandler: NSObject {
    var splashEventSink: FlutterEventSink?
    var interstitialEventSink: FlutterEventSink?
    var nativeEventSink: FlutterEventSink?
    private var splashAdManager: SplashAdManager?
    private var interstitialAdManager: InterstitialAdManager?
    private var bannerAdManagers: [String: BannerAdManager] = [:]
    private var nativeAdManagers: [String: NativeAdManager] = [:]
    private var channel: FlutterMethodChannel?
    
    public func register(with registrar: FlutterPluginRegistrar) {
        channel = FlutterMethodChannel(name: "multi_ads/pangle_global", binaryMessenger: registrar.messenger())
        channel?.setMethodCallHandler { [weak self] call, result in
            self?.handle(call, result: result)
        }
        
        let splashEventChannel = FlutterEventChannel(name: "multi_ads/pangle_global/splash_events", binaryMessenger: registrar.messenger())
        splashEventChannel.setStreamHandler(SplashEventStreamHandler(handler: self))
        
        let interstitialEventChannel = FlutterEventChannel(name: "multi_ads/pangle_global/interstitial_events", binaryMessenger: registrar.messenger())
        interstitialEventChannel.setStreamHandler(InterstitialEventStreamHandler(handler: self))
        
        let nativeEventChannel = FlutterEventChannel(name: "multi_ads/pangle_global/native_events", binaryMessenger: registrar.messenger())
        nativeEventChannel.setStreamHandler(NativeEventStreamHandler(handler: self))
        
        registrar.register(BannerAdViewFactory(messenger: registrar.messenger()), withId: "multi_ads/pangle_global/banner")
        
        // Register banner container for displaying pre-loaded banners
        registrar.register(BannerAdContainerFactory(messenger: registrar.messenger(), handler: self), withId: "multi_ads/pangle_global/banner_container")
        
        // Register native ad view factory
        registrar.register(NativeAdViewFactory(handler: self), withId: "multi_ads/pangle_global/native")
    }
    
    func getBannerView(listenerId: String) -> UIView? {
        return bannerAdManagers[listenerId]?.getBannerView()
    }
    
    func getNativeAd(listenerId: String) -> PAGLNativeAd? {
        return nativeAdManagers[listenerId]?.getNativeAd()
    }
    
    func updateNativeEventSink(_ sink: FlutterEventSink?) {
        self.nativeEventSink = sink
        for manager in nativeAdManagers.values {
            manager.updateEventSink(sink)
        }
    }

    func sendNativeSwipe(listenerId: String, direction: Int) {
        DispatchQueue.main.async {
            self.nativeEventSink?([
                "listenerId": listenerId,
                "event": "onAdSwipe",
                "direction": direction
            ])
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
            
        case "loadSplashAd":
            guard let args = call.arguments as? [String: Any],
                  let slotId = args["slotId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            let timeout = args["timeout"] as? Int ?? 3000
            loadSplashAd(slotId: slotId, timeout: timeout, result: result)
            
        case "loadInterstitialAd":
            guard let args = call.arguments as? [String: Any],
                  let slotId = args["slotId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadInterstitialAd(slotId: slotId, result: result)
            
        case "showInterstitialAd":
            showInterstitialAd(result: result)
            
        case "loadBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let slotId = args["slotId"] as? String,
                  let adSizeIndex = args["adSize"] as? Int,
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadBannerAd(slotId: slotId, adSizeIndex: adSizeIndex, listenerId: listenerId, result: result)
            
        case "showBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            showBannerAd(listenerId: listenerId, result: result)
            
        case "hideBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            hideBannerAd(listenerId: listenerId, result: result)
            
        case "disposeBannerAd":
            guard let args = call.arguments as? [String: Any],
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            disposeBannerAd(listenerId: listenerId, result: result)
            
        case "loadNativeAd":
            guard let args = call.arguments as? [String: Any],
                  let slotId = args["slotId"] as? String,
                  let listenerId = args["listenerId"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                return
            }
            loadNativeAd(slotId: slotId, listenerId: listenerId, result: result)
            
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
        let config = PAGConfig.share()
        config.appID = appId
        config.debugLog = debug
        
        config.paConsent = .consent
        config.gdprConsent = .consent
        
        PAGSdk.start(with: config) { success, error in
            if success {
                result(true)
            } else {
                result(false)
            }
        }
    }
    
    private func loadSplashAd(slotId: String, timeout: Int, result: @escaping FlutterResult) {
        splashAdManager = SplashAdManager(slotId: slotId, timeout: timeout, eventSink: splashEventSink)
        splashAdManager?.loadAd()
        result(nil)
    }
    
    private func loadInterstitialAd(slotId: String, result: @escaping FlutterResult) {
        interstitialAdManager = InterstitialAdManager(slotId: slotId, eventSink: interstitialEventSink)
        interstitialAdManager?.loadAd()
        result(true)
    }
    
    private func showInterstitialAd(result: @escaping FlutterResult) {
        interstitialAdManager?.showAd()
        result(nil)
    }
    
    private func loadBannerAd(slotId: String, adSizeIndex: Int, listenerId: String, result: @escaping FlutterResult) {
        guard let channel = self.channel else {
            result(FlutterError(code: "NO_CHANNEL", message: "Method channel not available", details: nil))
            return
        }
        
        // Convert adSizeIndex to PAGBannerAdSize
        let bannerSize: PAGBannerAdSize
        switch adSizeIndex {
        case 0:
            bannerSize = kPAGBannerSize320x50
        case 1:
            bannerSize = kPAGBannerSize300x250
        case 2:
            bannerSize = kPAGBannerSize728x90
        case 3:
            let screenWidth = UIScreen.main.bounds.width
            bannerSize = PAGCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(screenWidth)
        default:
            bannerSize = kPAGBannerSize320x50
        }
        
        // Dispose existing banner with same listenerId
        if let existingManager = bannerAdManagers[listenerId] {
            existingManager.dispose()
        }
        
        let bannerAdManager = BannerAdManager(listenerId: listenerId, slotId: slotId, adSize: bannerSize, channel: channel)
        bannerAdManagers[listenerId] = bannerAdManager
        bannerAdManager.loadAd()
        
        result(true)
    }
    
    private func showBannerAd(listenerId: String, result: @escaping FlutterResult) {
        guard let bannerAdManager = bannerAdManagers[listenerId] else {
            result(FlutterError(code: "NO_BANNER", message: "Banner ad not found", details: nil))
            return
        }
        
        let success = bannerAdManager.showAd()
        result(success)
    }
    
    private func hideBannerAd(listenerId: String, result: @escaping FlutterResult) {
        guard let bannerAdManager = bannerAdManagers[listenerId] else {
            result(FlutterError(code: "NO_BANNER", message: "Banner ad not found", details: nil))
            return
        }
        
        bannerAdManager.hideAd()
        result(nil)
    }
    
    private func disposeBannerAd(listenerId: String, result: @escaping FlutterResult) {
        guard let bannerAdManager = bannerAdManagers[listenerId] else {
            result(nil)
            return
        }
        
        bannerAdManager.dispose()
        bannerAdManagers.removeValue(forKey: listenerId)
        result(nil)
    }
    
    private func loadNativeAd(slotId: String, listenerId: String, result: @escaping FlutterResult) {
        // Dispose existing manager with same listenerId
        if let existing = nativeAdManagers[listenerId] {
            existing.dispose()
        }
        let manager = NativeAdManager(listenerId: listenerId, slotId: slotId, eventSink: nativeEventSink)
        nativeAdManagers[listenerId] = manager
        manager.loadAd()
        result(true)
    }
    
    private func disposeNativeAd(listenerId: String, result: @escaping FlutterResult) {
        if let manager = nativeAdManagers[listenerId] {
            manager.dispose()
            nativeAdManagers.removeValue(forKey: listenerId)
        }
        result(nil)
    }
}

class SplashEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: PangleAdsHandler?
    
    init(handler: PangleAdsHandler) {
        self.handler = handler
    }
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        handler?.splashEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        handler?.splashEventSink = nil
        return nil
    }
}

class InterstitialEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: PangleAdsHandler?
    
    init(handler: PangleAdsHandler) {
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

class NativeEventStreamHandler: NSObject, FlutterStreamHandler {
    weak var handler: PangleAdsHandler?
    
    init(handler: PangleAdsHandler) {
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
