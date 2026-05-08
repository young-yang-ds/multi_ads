import Foundation
import Flutter
import VungleAdsSDK

class VungleNativeAdManager: NSObject {
    private var nativeAd: VungleNative?
    private var eventSink: FlutterEventSink?
    private let listenerId: String
    private let placementId: String
    
    init(listenerId: String, placementId: String, eventSink: FlutterEventSink?) {
        self.listenerId = listenerId
        self.placementId = placementId
        self.eventSink = eventSink
        super.init()
    }
    
    func updateEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    func loadAd() {
        print("[VungleNativeAd] Loading ad for listener: \(listenerId), placement: \(placementId)")
        nativeAd = VungleNative(placementId: placementId)
        nativeAd?.delegate = self
        nativeAd?.load()
    }
    
    func getNativeAd() -> VungleNative? {
        return nativeAd
    }
    
    func dispose() {
        print("[VungleNativeAd] Disposing ad for listener: \(listenerId), placement: \(placementId)")
        nativeAd?.delegate = nil
        nativeAd = nil
    }
}

// MARK: - VungleNativeDelegate
extension VungleNativeAdManager: VungleNativeDelegate {
    func nativeAdDidLoad(_ native: VungleNative) {
        print("[VungleNativeAd] Ad loaded for listener: \(listenerId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdLoaded",
                "listenerId": self.listenerId,
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidFailToLoad(_ native: VungleNative, withError: NSError) {
        print("[VungleNativeAd] Ad load failed for listener: \(listenerId), error: \(withError.localizedDescription)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdLoadFailed",
                "listenerId": self.listenerId,
                "placementId": self.placementId,
                "error": [
                    "code": withError.code,
                    "message": withError.localizedDescription
                ]
            ])
        }
    }
    
    func nativeAdDidTrackImpression(_ native: VungleNative) {
        print("[VungleNativeAd] Ad impression for listener: \(listenerId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdImpression",
                "listenerId": self.listenerId,
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidClick(_ native: VungleNative) {
        print("[VungleNativeAd] Ad clicked for listener: \(listenerId)")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdClicked",
                "listenerId": self.listenerId,
                "placementId": self.placementId
            ])
        }
    }
    
    func nativeAdDidFailToPresent(_ native: VungleNative, withError: NSError) {
        print("[VungleNativeAd] Ad failed to present for listener: \(listenerId), error: \(withError.localizedDescription)")
    }
}
