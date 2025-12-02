import Foundation
import Flutter
import PAGAdSDK

class BannerAdContainerFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private weak var handler: PangleAdsHandler?
    
    init(messenger: FlutterBinaryMessenger, handler: PangleAdsHandler) {
        self.messenger = messenger
        self.handler = handler
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return BannerAdContainerView(frame: frame, viewId: viewId, args: args, handler: handler)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class BannerAdContainerView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    private weak var handler: PangleAdsHandler?
    private var listenerId: String?
    
    init(frame: CGRect, viewId: Int64, args: Any?, handler: PangleAdsHandler?) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        self.handler = handler
        super.init()
        
        if let args = args as? [String: Any],
           let listenerId = args["listenerId"] as? String {
            self.listenerId = listenerId
            DispatchQueue.main.async { [weak self] in
                self?.displayBannerAd()
            }
        }
    }
    
    private func displayBannerAd() {
        guard let listenerId = listenerId,
              let bannerView = handler?.getBannerView(listenerId: listenerId) else {
            return
        }
        
        bannerView.removeFromSuperview()
        
        // Add to container
        containerView.addSubview(bannerView)
        
        // Fill the container
        bannerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bannerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            bannerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            bannerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            bannerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor)
        ])
        
        bannerView.isUserInteractionEnabled = true
        containerView.isUserInteractionEnabled = true
    }
    
    func view() -> UIView {
        return containerView
    }
}
