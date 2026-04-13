import Foundation
import Flutter
import VungleAdsSDK

class VungleNativeAdManager: NSObject {
    private var nativeAd: VungleNative?
    private var eventSink: FlutterEventSink?
    private let placementId: String
    
    init(placementId: String, eventSink: FlutterEventSink?) {
        self.placementId = placementId
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        print("[VungleNativeAd] Loading ad for placement: \(placementId)")
        nativeAd = VungleNative(placementId: placementId)
        nativeAd?.delegate = self
        nativeAd?.load()
    }
    
    func getNativeAd() -> VungleNative? {
        return nativeAd
    }
    
    func dispose() {
        print("[VungleNativeAd] Disposing ad for placement: \(placementId)")
        nativeAd?.delegate = nil
        nativeAd = nil
    }
}

// MARK: - VungleNativeDelegate
extension VungleNativeAdManager: VungleNativeDelegate {
    func nativeAdDidLoad(_ native: VungleNative) {
        print("[VungleNativeAd] Ad loaded for placement: \(placementId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdLoaded",
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidFailToLoad(_ native: VungleNative, withError: NSError) {
        print("[VungleNativeAd] Ad load failed for placement: \(placementId), error: \(withError.localizedDescription)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdLoadFailed",
                "placementId": self.placementId,
                "error": [
                    "code": withError.code,
                    "message": withError.localizedDescription
                ]
            ])
        }
    }
    
    func nativeAdDidTrackImpression(_ native: VungleNative) {
        print("[VungleNativeAd] Ad impression for placement: \(placementId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdImpression",
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidClick(_ native: VungleNative) {
        print("[VungleNativeAd] Ad clicked for placement: \(placementId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdClicked",
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidFailToPresent(_ native: VungleNative, withError: NSError) {
        print("[VungleNativeAd] Ad failed to present for placement: \(placementId), error: \(withError.localizedDescription)")
    }
}
