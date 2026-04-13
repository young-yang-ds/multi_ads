import Foundation
import UIKit
import google_mobile_ads
import GoogleMobileAds
import multi_ads

class NativeAdFactoryImpl: FLTNativeAdFactory {
    func createNativeAd(
        _ nativeAd: NativeAd,
        customOptions: [AnyHashable: Any]?
    ) -> NativeAdView? {
        return NativeAdViewBuilder.build(nativeAd: nativeAd, customOptions: customOptions)
    }
}
