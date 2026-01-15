import Flutter
import UIKit
import VungleAdsSDK

class VungleAppOpenAdManager: NSObject {
    private let placementId: String
    private var eventSink: FlutterEventSink?
    private var interstitialAd: VungleInterstitial?
    
    init(placementId: String, eventSink: FlutterEventSink?) {
        self.placementId = placementId
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        print("[VungleAppOpenAd] Loading ad for placement: \(placementId)")
        
        interstitialAd = VungleInterstitial(placementId: placementId)
        interstitialAd?.delegate = self
        interstitialAd?.load()
    }
    
    func showAd() {
        print("[VungleAppOpenAd] Showing ad for placement: \(placementId)")
        
        guard let ad = interstitialAd, ad.canPlayAd() else {
            print("[VungleAppOpenAd] Ad cannot be played")
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

extension VungleAppOpenAdManager: VungleInterstitialDelegate {
    func interstitialAdDidLoad(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdLoaded: \(placementId)")
        sendEvent("onAdLoaded")
    }
    
    func interstitialAdDidFailToLoad(_ interstitial: VungleInterstitial, withError: NSError) {
        print("[VungleAppOpenAd] onAdLoadFailed: \(placementId), error: \(withError.localizedDescription)")
        sendEvent("onAdLoadFailed", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func interstitialAdWillPresent(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdWillPresent: \(placementId)")
    }
    
    func interstitialAdDidPresent(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdShowed: \(placementId)")
        sendEvent("onAdShowed")
    }
    
    func interstitialAdDidFailToPresent(_ interstitial: VungleInterstitial, withError: NSError) {
        print("[VungleAppOpenAd] onAdFailedToPlay: \(placementId), error: \(withError.localizedDescription)")
        sendEvent("onAdFailedToPlay", additionalData: [
            "error": ["code": withError.code, "message": withError.localizedDescription]
        ])
    }
    
    func interstitialAdDidTrackImpression(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdImpression: \(placementId)")
        sendEvent("onAdImpression")
    }
    
    func interstitialAdDidClick(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdClicked: \(placementId)")
        sendEvent("onAdClicked")
    }
    
    func interstitialAdWillLeaveApplication(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdWillLeaveApplication: \(placementId)")
    }
    
    func interstitialAdWillClose(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdWillClose: \(placementId)")
    }
    
    func interstitialAdDidClose(_ interstitial: VungleInterstitial) {
        print("[VungleAppOpenAd] onAdDismissed: \(placementId)")
        sendEvent("onAdDismissed")
    }
}
