import Flutter
import UIKit
import VungleAdsSDK

class VungleBannerAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private weak var handler: VungleAdsHandler?
    
    init(messenger: FlutterBinaryMessenger, handler: VungleAdsHandler) {
        self.messenger = messenger
        self.handler = handler
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return VungleBannerAdPlatformView(
            frame: frame,
            viewId: viewId,
            args: args as? [String: Any] ?? [:],
            messenger: messenger
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class VungleBannerAdPlatformView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    private var bannerAd: VungleBanner?
    private let listenerId: String
    private var channel: FlutterMethodChannel
    
    init(frame: CGRect, viewId: Int64, args: [String: Any], messenger: FlutterBinaryMessenger) {
        self.containerView = UIView(frame: frame)
        self.listenerId = args["listenerId"] as? String ?? ""
        self.channel = FlutterMethodChannel(name: "multi_ads/vungle", binaryMessenger: messenger)
        
        super.init()
        
        let placementId = args["placementId"] as? String ?? ""
        let bannerSize = args["bannerSize"] as? Int ?? 0
        
        print("[VungleBannerView] Creating - placementId: \(placementId), size: \(bannerSize), listenerId: \(listenerId)")
        
        let vungleBannerSize: BannerSize
        switch bannerSize {
        case 0:
            vungleBannerSize = .regular
        case 1:
            vungleBannerSize = .short
        case 2:
            vungleBannerSize = .leaderboard
        case 3:
            vungleBannerSize = .mrec
        default:
            vungleBannerSize = .regular
        }
        
        bannerAd = VungleBanner(placementId: placementId, size: vungleBannerSize)
        bannerAd?.delegate = self
        bannerAd?.load()
    }
    
    func view() -> UIView {
        return containerView
    }
    
    private func sendCallback(_ methodName: String, additionalData: [String: Any] = [:]) {
        var args: [String: Any] = [
            "listenerId": listenerId
        ]
        args.merge(additionalData) { (_, new) in new }
        channel.invokeMethod(methodName, arguments: args)
    }
}

// MARK: - VungleBannerDelegate

extension VungleBannerAdPlatformView: VungleBannerDelegate {
    func bannerAdDidLoad(_ banner: VungleBanner) {
        print("[VungleBannerView] onAdLoaded - listenerId: \(listenerId)")
        banner.present(on: containerView)
        sendCallback("onBannerAdLoaded")
    }
    
    func bannerAdDidFailToLoad(_ banner: VungleBanner, withError: NSError) {
        print("[VungleBannerView] onAdLoadFailed - listenerId: \(listenerId), error: \(withError.localizedDescription)")
        sendCallback("onBannerAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func bannerAdWillPresent(_ banner: VungleBanner) {}
    
    func bannerAdDidPresent(_ banner: VungleBanner) {
        print("[VungleBannerView] onAdShowed - listenerId: \(listenerId)")
        sendCallback("onBannerAdShowed")
    }
    
    func bannerAdDidFailToPresent(_ banner: VungleBanner, withError: NSError) {
        print("[VungleBannerView] onAdFailedToPresent - listenerId: \(listenerId)")
    }
    
    func bannerAdDidTrackImpression(_ banner: VungleBanner) {}
    
    func bannerAdDidClick(_ banner: VungleBanner) {
        print("[VungleBannerView] onAdClicked - listenerId: \(listenerId)")
        sendCallback("onBannerAdClicked")
    }
    
    func bannerAdWillLeaveApplication(_ banner: VungleBanner) {}
    func bannerAdWillClose(_ banner: VungleBanner) {}
    func bannerAdDidClose(_ banner: VungleBanner) {}
}
