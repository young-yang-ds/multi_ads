import Foundation
import Flutter
import PAGAdSDK

class BannerAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    
    init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return BannerAdView(frame: frame, viewId: viewId, args: args, messenger: messenger)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class BannerAdView: NSObject, FlutterPlatformView {
    private var bannerView: UIView
    private var bannerAd: PAGBannerAd?
    private var channel: FlutterMethodChannel
    
    init(frame: CGRect, viewId: Int64, args: Any?, messenger: FlutterBinaryMessenger) {
        channel = FlutterMethodChannel(name: "multi_ads/pangle_global", binaryMessenger: messenger)
        bannerView = UIView(frame: frame)
        bannerView.backgroundColor = .clear
        super.init()
        
        if let args = args as? [String: Any],
           let slotId = args["slotId"] as? String,
           let adSizeIndex = args["adSize"] as? Int {
            loadBannerAd(slotId: slotId, adSizeIndex: adSizeIndex)
        }
    }
    
    func view() -> UIView {
        return bannerView
    }
    
    private func loadBannerAd(slotId: String, adSizeIndex: Int) {
        let bannerSize: PAGBannerAdSize
        switch adSizeIndex {
        case 0:
            bannerSize = kPAGBannerSize320x50
        case 1:
            bannerSize = kPAGBannerSize300x250
        case 2:
            bannerSize = kPAGBannerSize728x90
        case 3:
            let screenWidth = UIScreen.main.bounds.width
            bannerSize = PAGCurrentOrientationAnchoredAdaptiveBannerAdSizeWithWidth(screenWidth)
        default:
            bannerSize = kPAGBannerSize320x50
        }
        
        let request = PAGBannerRequest(bannerSize: bannerSize)
        
        PAGBannerAd.load(withSlotID: slotId, request: request) { [weak self] ad, error in
            guard let self = self else { return }
            
            if let error = error {
                let errorCode = (error as NSError).code
                DispatchQueue.main.async {
                    self.channel.invokeMethod("onBannerAdLoadFailed", arguments: [
                        "code": errorCode,
                        "message": error.localizedDescription
                    ])
                }
                return
            }
            
            if let ad = ad {
                self.bannerAd = ad
                
                if let rootVC = UIApplication.shared.windows.first?.rootViewController {
                    ad.rootViewController = rootVC
                }
                
                ad.delegate = self
                
                DispatchQueue.main.async {
                    let adView = ad.bannerView
                    self.bannerView.subviews.forEach { $0.removeFromSuperview() }
                    self.bannerView.addSubview(adView)
                    adView.frame = self.bannerView.bounds
                    adView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
                    adView.isUserInteractionEnabled = true
                    self.bannerView.isUserInteractionEnabled = true
                    self.channel.invokeMethod("onBannerAdLoaded", arguments: nil)
                }
            }
        }
    }
}

extension BannerAdView: PAGBannerAdDelegate {
    func adDidShow(_ ad: PAGAdProtocol) {
    }
    
    func adDidClick(_ ad: PAGAdProtocol) {
        DispatchQueue.main.async {
            self.channel.invokeMethod("onBannerAdClicked", arguments: nil)
        }
    }
    
    func adDidDismiss(_ ad: PAGAdProtocol) {
    }
}
