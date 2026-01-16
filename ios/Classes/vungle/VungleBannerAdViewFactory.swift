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
        self.listenerId = args["listenerId"] as? String ?? ""
        self.channel = FlutterMethodChannel(name: "multi_ads/vungle", binaryMessenger: messenger)
        
        let placementId = args["placementId"] as? String ?? ""
        let bannerSizeIndex = args["bannerSize"] as? Int ?? 0
        
        // 根据尺寸确定广告大小
        let vungleBannerSize: BannerSize
        let adSize: CGSize
        switch bannerSizeIndex {
        case 0:
            vungleBannerSize = .regular
            adSize = CGSize(width: 320, height: 50)
        case 1:
            vungleBannerSize = .short
            adSize = CGSize(width: 300, height: 50)
        case 2:
            vungleBannerSize = .leaderboard
            adSize = CGSize(width: 728, height: 90)
        case 3:
            vungleBannerSize = .mrec
            adSize = CGSize(width: 300, height: 250)
        default:
            vungleBannerSize = .regular
            adSize = CGSize(width: 320, height: 50)
        }
        
        // 使用固定尺寸创建容器
        self.containerView = UIView(frame: CGRect(origin: .zero, size: adSize))
        self.containerView.backgroundColor = .clear
        
        super.init()
        
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
        // 在主线程调用 present
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let bannerAd = self.bannerAd, bannerAd.canPlayAd() {
                bannerAd.present(on: self.containerView)
            }
        }
        
        sendCallback("onBannerAdLoaded")
    }
    
    func bannerAdDidFailToLoad(_ banner: VungleBanner, withError: NSError) {
        sendCallback("onBannerAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func bannerAdWillPresent(_ banner: VungleBanner) {}
    
    func bannerAdDidPresent(_ banner: VungleBanner) {
        sendCallback("onBannerAdShowed")
    }
    
    func bannerAdDidFailToPresent(_ banner: VungleBanner, withError: NSError) {}
    
    func bannerAdDidTrackImpression(_ banner: VungleBanner) {}
    
    func bannerAdDidClick(_ banner: VungleBanner) {
        sendCallback("onBannerAdClicked")
    }
    
    func bannerAdWillLeaveApplication(_ banner: VungleBanner) {}
    func bannerAdWillClose(_ banner: VungleBanner) {}
    func bannerAdDidClose(_ banner: VungleBanner) {}
}
