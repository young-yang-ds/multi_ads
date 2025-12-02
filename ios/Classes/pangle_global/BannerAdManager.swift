import Foundation
import Flutter
import PAGAdSDK

class BannerAdManager: NSObject {
    private var bannerAd: PAGBannerAd?
    private var channel: FlutterMethodChannel
    private let listenerId: String
    private let slotId: String
    private let adSize: PAGBannerAdSize
    
    init(listenerId: String, slotId: String, adSize: PAGBannerAdSize, channel: FlutterMethodChannel) {
        self.listenerId = listenerId
        self.slotId = slotId
        self.adSize = adSize
        self.channel = channel
        super.init()
    }
    
    func loadAd() {
        let request = PAGBannerRequest(bannerSize: adSize)
        
        PAGBannerAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                let errorCode = (error as NSError).code
                DispatchQueue.main.async {
                    self.channel.invokeMethod("onBannerAdLoadFailed", arguments: [
                        "listenerId": self.listenerId,
                        "error": [
                            "code": errorCode,
                            "message": error.localizedDescription
                        ]
                    ])
                }
                return
            }
            
            if let ad = ad {
                self.bannerAd = ad
                
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    ad.rootViewController = rootVC
                }
                
                // Set delegate
                ad.delegate = self
                
                DispatchQueue.main.async {
                    self.channel.invokeMethod("onBannerAdLoaded", arguments: [
                        "listenerId": self.listenerId
                    ])
                }
            }
        }
    }
    
    func showAd() -> Bool {
        guard let bannerAd = bannerAd else {
            return false
        }
        
        guard let rootVC = UIApplication.shared.windows.first?.rootViewController else {
            return false
        }
        
        let adView = bannerAd.bannerView
        
        // Remove from any existing parent
        adView.removeFromSuperview()
        
        // Add to root view controller
        rootVC.view.addSubview(adView)
        
        // Position at bottom of screen
        adView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            adView.centerXAnchor.constraint(equalTo: rootVC.view.centerXAnchor),
            adView.bottomAnchor.constraint(equalTo: rootVC.view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            adView.widthAnchor.constraint(equalToConstant: adSize.size.width),
            adView.heightAnchor.constraint(equalToConstant: adSize.size.height)
        ])
        
        DispatchQueue.main.async {
            self.channel.invokeMethod("onBannerAdShowed", arguments: [
                "listenerId": self.listenerId
            ])
        }
        
        return true
    }
    
    func hideAd() {
        guard let bannerAd = bannerAd else {
            return
        }
        bannerAd.bannerView.removeFromSuperview()
    }
    
    func dispose() {
        hideAd()
        bannerAd = nil
    }
    
    func getBannerView() -> UIView? {
        return bannerAd?.bannerView
    }
    
    var isLoaded: Bool {
        return bannerAd != nil
    }
}

// MARK: - PAGBannerAdDelegate
extension BannerAdManager: PAGBannerAdDelegate {
    func adDidShow(_ ad: PAGAdProtocol) {
    }
    
    func adDidClick(_ ad: PAGAdProtocol) {
        DispatchQueue.main.async {
            self.channel.invokeMethod("onBannerAdClicked", arguments: [
                "listenerId": self.listenerId
            ])
        }
    }
    
    func adDidDismiss(_ ad: PAGAdProtocol) {
        DispatchQueue.main.async {
            self.channel.invokeMethod("onBannerAdDismissed", arguments: [
                "listenerId": self.listenerId
            ])
        }
    }
}
