import Foundation
import PAGAdSDK
import Flutter

class SplashAdManager: NSObject {
    private let slotId: String
    private let timeout: Int
    private var eventSink: FlutterEventSink?
    private var splashAd: PAGLAppOpenAd?
    
    init(slotId: String, timeout: Int, eventSink: FlutterEventSink?) {
        self.slotId = slotId
        self.timeout = timeout
        self.eventSink = eventSink
        super.init()
    }
    
    func loadAd() {
        let request = PAGAppOpenRequest()
        
        PAGLAppOpenAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    let errorCode = (error as NSError).code
                    self.eventSink?(["event": "onAdLoadFailed", "error": ["code": errorCode, "message": error.localizedDescription]])
                }
                return
            }
            
            if let ad = ad {
                self.splashAd = ad
                ad.delegate = self
                DispatchQueue.main.async {
                    self.eventSink?(["event": "onAdLoaded"])
                    self.showAd()
                }
            }
        }
    }
    
    private func showAd() {
        guard let rootViewController = UIApplication.shared.windows.first?.rootViewController else {
            return
        }
        splashAd?.present(fromRootViewController: rootViewController)
    }
}

extension SplashAdManager: PAGLAppOpenAdDelegate {
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
