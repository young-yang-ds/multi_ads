import Flutter
import UIKit

public class MultiAdsPlugin: NSObject, FlutterPlugin {
  private static var pangleAdsHandler: PangleAdsHandler?
  private static var vungleAdsHandler: VungleAdsHandler?
  
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "multi_ads", binaryMessenger: registrar.messenger())
    let instance = MultiAdsPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
    
    // Initialize Pangle Ads Handler
    pangleAdsHandler = PangleAdsHandler()
    pangleAdsHandler?.register(with: registrar)
    
    // Initialize Vungle Ads Handler
    vungleAdsHandler = VungleAdsHandler()
    vungleAdsHandler?.register(with: registrar)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

