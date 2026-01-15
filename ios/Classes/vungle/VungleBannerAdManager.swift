import Flutter
import UIKit
import VungleAdsSDK

class VungleBannerAdManager: NSObject {
    private let listenerId: String
    private let placementId: String
    private let bannerSize: Int
    private var channel: FlutterMethodChannel
    private var bannerAd: VungleBanner?
    private var bannerView: UIView?
    
    init(listenerId: String, placementId: String, bannerSize: Int, channel: FlutterMethodChannel) {
        self.listenerId = listenerId
        self.placementId = placementId
        self.bannerSize = bannerSize
        self.channel = channel
        super.init()
    }
    
    private func getVungleBannerSize() -> BannerSize {
        switch bannerSize {
        case 0:
            return .regular // 320x50
        case 1:
            return .short // 300x50
        case 2:
            return .leaderboard // 728x90
        case 3:
            return .mrec // 300x250
        default:
            return .regular
        }
    }
    
    func loadAd() {
        print("[VungleBannerAd] Loading ad - listenerId: \(listenerId), placementId: \(placementId), size: \(bannerSize)")
        
        bannerAd = VungleBanner(placementId: placementId, size: getVungleBannerSize())
        bannerAd?.delegate = self
        bannerAd?.load()
    }
    
    func getBannerView() -> UIView? {
        return bannerView
    }
    
    func dispose() {
        print("[VungleBannerAd] Disposing ad - listenerId: \(listenerId)")
        bannerAd?.delegate = nil
        bannerAd = nil
        bannerView = nil
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

extension VungleBannerAdManager: VungleBannerDelegate {
    func bannerAdDidLoad(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdLoaded - listenerId: \(listenerId)")
        sendCallback("onBannerAdLoaded")
    }
    
    func bannerAdDidFailToLoad(_ banner: VungleBanner, withError: NSError) {
        print("[VungleBannerAd] onAdLoadFailed - listenerId: \(listenerId), error: \(withError.localizedDescription)")
        sendCallback("onBannerAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func bannerAdWillPresent(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdWillPresent - listenerId: \(listenerId)")
    }
    
    func bannerAdDidPresent(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdShowed - listenerId: \(listenerId)")
        sendCallback("onBannerAdShowed")
    }
    
    func bannerAdDidFailToPresent(_ banner: VungleBanner, withError: NSError) {
        print("[VungleBannerAd] onAdFailedToPresent - listenerId: \(listenerId), error: \(withError.localizedDescription)")
        sendCallback("onBannerAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func bannerAdDidTrackImpression(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdImpression - listenerId: \(listenerId)")
        sendCallback("onBannerAdImpression")
    }
    
    func bannerAdDidClick(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdClicked - listenerId: \(listenerId)")
        sendCallback("onBannerAdClicked")
    }
    
    func bannerAdWillLeaveApplication(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdWillLeaveApplication - listenerId: \(listenerId)")
    }
    
    func bannerAdWillClose(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdWillClose - listenerId: \(listenerId)")
    }
    
    func bannerAdDidClose(_ banner: VungleBanner) {
        print("[VungleBannerAd] onAdClosed - listenerId: \(listenerId)")
        sendCallback("onBannerAdClosed")
    }
}
