import '../../multi_ads.dart';
import '../google_ads/google_ads_service/google_open_ad.dart';
import '../models/ad_error.dart';
import '../pangle_global/splash_ad.dart';
import '../vungle/app_open_ad.dart';
import 'log_utils.dart';

class OpenUtils {
  static PangleSplashAd? _pangleSplashAd;
  static VungleAppOpenAd? _vungleAppOpenAd;

  static void loadAndShow(
    String adUnitId,
    AdPlatform adPlatform, {
    int timeout = 3000,
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdSkippedHandle,
  }) {
    LogUtils.log('Open ad loadAndShow, adPlatform: $adPlatform', tag: 'open');

    if (adPlatform == AdPlatform.google) {
      GoogleOpenAd.loadAndShow(
        adUnitId,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: (code, message) {
          onAdFailedToShowHandle?.call(
            AdError(code: code, message: message, platform: 'google'),
          );
        },
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
      );
    } else if (adPlatform == AdPlatform.pangleGlobal) {
      _pangleSplashAd = PangleSplashAd(
        slotId: adUnitId,
        timeout: timeout,
        onAdLoaded: () {
          onAdShowedHandle?.call();
        },
        onAdLoadFailed: (error) {
          onAdFailedToShowHandle?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'pangle',
            ),
          );
        },
        onAdClicked: () {
          onAdClickedHandle?.call();
        },
        onAdSkipped: () {
          onAdSkippedHandle?.call();
        },
        onAdDismissed: () {
          onAdDismissHandle?.call();
        },
      );
      _pangleSplashAd?.load();
    } else if (adPlatform == AdPlatform.vungle) {
      _vungleAppOpenAd = VungleAppOpenAd(
        placementId: adUnitId,
        onAdLoaded: () {
          _vungleAppOpenAd?.show();
        },
        onAdLoadFailed: (error) {
          onAdFailedToShowHandle?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'vungle',
            ),
          );
        },
        onAdShowed: () {
          onAdShowedHandle?.call();
        },
        onAdClicked: () {
          onAdClickedHandle?.call();
        },
        onAdDismissed: () {
          onAdDismissHandle?.call();
        },
        onAdFailedToPlay: (error) {
          onAdFailedToShowHandle?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'vungle',
            ),
          );
        },
      );
      _vungleAppOpenAd?.load();
    }
  }

  static void dispose() {
    GoogleOpenAd.dispose();
    _pangleSplashAd = null;
    _vungleAppOpenAd = null;
  }
}
