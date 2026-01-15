import Flutter
import UIKit

class VungleBannerAdContainerFactory: NSObject, FlutterPlatformViewFactory {
    private weak var handler: VungleAdsHandler?
    
    init(handler: VungleAdsHandler) {
        self.handler = handler
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return VungleBannerAdContainerView(
            frame: frame,
            viewId: viewId,
            args: args as? [String: Any] ?? [:],
            handler: handler
        )
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class VungleBannerAdContainerView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    
    init(frame: CGRect, viewId: Int64, args: [String: Any], handler: VungleAdsHandler?) {
        self.containerView = UIView(frame: frame)
        
        super.init()
        
        let listenerId = args["listenerId"] as? String ?? ""
        print("[VungleBannerContainer] Creating for listenerId: \(listenerId)")
        
        if let bannerView = handler?.getBannerView(listenerId: listenerId) {
            bannerView.removeFromSuperview()
            containerView.addSubview(bannerView)
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
                bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
                bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
            ])
            print("[VungleBannerContainer] Banner view added")
        } else {
            print("[VungleBannerContainer] Banner view not found for listenerId: \(listenerId)")
        }
    }
    
    func view() -> UIView {
        return containerView
    }
}
