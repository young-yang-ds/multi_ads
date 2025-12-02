import Foundation
import PAGAdSDK
import Flutter

class InterstitialAdManager: NSObject {
    private let slotId: String
    private var eventSink: FlutterEventSink?
    private var interstitialAd: PAGLInterstitialAd?
    
    init(slotId: String, eventSink: FlutterEventSink?) {
        self.slotId = slotId
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        let request = PAGInterstitialRequest()
        
        PAGLInterstitialAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    let errorCode = (error as NSError).code
                    self.eventSink?(["event": "onAdLoadFailed", "error": ["code": errorCode, "message": error.localizedDescription]])
                }
                return
            }
            
            if let ad = ad {
                self.interstitialAd = ad
                ad.delegate = self
                DispatchQueue.main.async {
                    self.eventSink?(["event": "onAdLoaded"])
                }
            }
        }
    }
    
    func showAd() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        interstitialAd?.present(fromRootViewController: rootViewController)
    }
}

extension InterstitialAdManager: PAGLInterstitialAdDelegate {
    func adDidShow(_ ad: PAGAdProtocol) {
        eventSink?(["event": "onAdShowed"])
    }
    
    func adDidClick(_ ad: PAGAdProtocol) {
        eventSink?(["event": "onAdClicked"])
    }
    
    func adDidDismiss(_ ad: PAGAdProtocol) {
        eventSink?(["event": "onAdDismissed"])
    }
}
