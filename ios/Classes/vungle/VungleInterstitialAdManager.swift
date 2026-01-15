import Flutter
import UIKit
import VungleAdsSDK

class VungleInterstitialAdManager: NSObject {
    private let placementId: String
    private var eventSink: FlutterEventSink?
    private var interstitialAd: VungleInterstitial?
    
    init(placementId: String, eventSink: FlutterEventSink?) {
        self.placementId = placementId
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        print("[VungleInterstitialAd] Loading ad for placement: \(placementId)")
        
        interstitialAd = VungleInterstitial(placementId: placementId)
        interstitialAd?.delegate = self
        interstitialAd?.load()
    }
    
    func showAd() {
        print("[VungleInterstitialAd] Showing ad for placement: \(placementId)")
        
        guard let ad = interstitialAd, ad.canPlayAd() else {
            print("[VungleInterstitialAd] Ad cannot be played")
            sendEvent("onAdFailedToPlay", additionalData: [
                "error": ["code": -1, "message": "Ad cannot be played"]
            ])
            return
        }
        
        if let rootViewController = UIApplication.shared.keyWindow?.rootViewController {
            ad.present(with: rootViewController)
        }
    }
    
    func canPlayAd() -> Bool {
        return interstitialAd?.canPlayAd() ?? false
    }
    
    func dispose() {
        interstitialAd?.delegate = nil
        interstitialAd = nil
    }
    
    private func sendEvent(_ eventType: String, additionalData: [String: Any] = [:]) {
        var eventData: [String: Any] = [
            "event": eventType,
            "placementId": placementId
        ]
        eventData.merge(additionalData) { (_, new) in new }
        eventSink?(eventData)
    }
}

// MARK: - VungleInterstitialDelegate

extension VungleInterstitialAdManager: VungleInterstitialDelegate {
    func interstitialAdDidLoad(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdLoaded: \(placementId)")
        sendEvent("onAdLoaded")
    }
    
    func interstitialAdDidFailToLoad(_ interstitial: VungleInterstitial, withError: NSError) {
        print("[VungleInterstitialAd] onAdLoadFailed: \(placementId), error: \(withError.localizedDescription)")
        sendEvent("onAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func interstitialAdWillPresent(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdWillPresent: \(placementId)")
    }
    
    func interstitialAdDidPresent(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdShowed: \(placementId)")
        sendEvent("onAdShowed")
    }
    
    func interstitialAdDidFailToPresent(_ interstitial: VungleInterstitial, withError: NSError) {
        print("[VungleInterstitialAd] onAdFailedToPlay: \(placementId), error: \(withError.localizedDescription)")
        sendEvent("onAdFailedToPlay", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func interstitialAdDidTrackImpression(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdImpression: \(placementId)")
        sendEvent("onAdImpression")
    }
    
    func interstitialAdDidClick(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdClicked: \(placementId)")
        sendEvent("onAdClicked")
    }
    
    func interstitialAdWillLeaveApplication(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdWillLeaveApplication: \(placementId)")
    }
    
    func interstitialAdWillClose(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdWillClose: \(placementId)")
    }
    
    func interstitialAdDidClose(_ interstitial: VungleInterstitial) {
        print("[VungleInterstitialAd] onAdDismissed: \(placementId)")
        sendEvent("onAdDismissed")
    }
}
