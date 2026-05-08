import Foundation
import Flutter
import PAGAdSDK

class NativeAdManager: NSObject {
    private var nativeAd: PAGLNativeAd?
    private var eventSink: FlutterEventSink?
    private let listenerId: String
    private let slotId: String
    
    init(listenerId: String, slotId: String, eventSink: FlutterEventSink?) {
        self.listenerId = listenerId
        self.slotId = slotId
        self.eventSink = eventSink
        super.init()
    }
    
    func updateEventSink(_ sink: FlutterEventSink?) {
        self.eventSink = sink
    }
    
    func loadAd() {
        print("[PangleNativeAd] Loading ad with listenerId: \(listenerId), slotId: \(slotId)")
        let request = PAGNativeRequest()
        
        PAGLNativeAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                let errorCode = (error as NSError).code
                print("[PangleNativeAd] Ad load failed (\(self.listenerId)): \(errorCode) - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.eventSink?([
                        "listenerId": self.listenerId,
                        "event": "onAdLoadFailed",
                        "error": [
                            "code": errorCode,
                            "message": error.localizedDescription
                        ]
                    ])
                }
                return
            }
            
            if let ad = ad {
                self.nativeAd = ad
                ad.delegate = self
                print("[PangleNativeAd] Ad loaded successfully (\(self.listenerId))")
                
                DispatchQueue.main.async {
                    self.eventSink?([
                        "listenerId": self.listenerId,
                        "event": "onAdLoaded"
                    ])
                }
            }
        }
    }
    
    func getNativeAd() -> PAGLNativeAd? {
        return nativeAd
    }
    
    func dispose() {
        print("[PangleNativeAd] Disposing ad (\(listenerId))")
        nativeAd = nil
    }
}

// MARK: - PAGLNativeAdDelegate
extension NativeAdManager: PAGLNativeAdDelegate {
    func adDidShow(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad showed (\(listenerId))")
        DispatchQueue.main.async {
            self.eventSink?([
                "listenerId": self.listenerId,
                "event": "onAdShowed"
            ])
        }
    }
    
    func adDidClick(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad clicked (\(listenerId))")
        DispatchQueue.main.async {
            self.eventSink?([
                "listenerId": self.listenerId,
                "event": "onAdClicked"
            ])
        }
    }
    
    func adDidDismiss(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad dismissed (\(listenerId))")
    }
}
