import Foundation
import Flutter
import PAGAdSDK

class NativeAdManager: NSObject {
    private var nativeAd: PAGLNativeAd?
    private var eventSink: FlutterEventSink?
    private let slotId: String
    
    init(slotId: String, eventSink: FlutterEventSink?) {
        self.slotId = slotId
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        print("[PangleNativeAd] Loading ad with slotId: \(slotId)")
        let request = PAGNativeRequest()
        
        PAGLNativeAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                let errorCode = (error as NSError).code
                print("[PangleNativeAd] Ad load failed: \(errorCode) - \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.eventSink?([
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
                print("[PangleNativeAd] Ad loaded successfully")
                
                DispatchQueue.main.async {
                    self.eventSink?([
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
        print("[PangleNativeAd] Disposing ad")
        nativeAd = nil
    }
}

// MARK: - PAGLNativeAdDelegate
extension NativeAdManager: PAGLNativeAdDelegate {
    func adDidShow(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad showed")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdShowed"
            ])
        }
    }
    
    func adDidClick(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad clicked")
        DispatchQueue.main.async {
            self.eventSink?([
                "event": "onAdClicked"
            ])
        }
    }
    
    func adDidDismiss(_ ad: PAGAdProtocol) {
        print("[PangleNativeAd] Ad dismissed")
    }
}
