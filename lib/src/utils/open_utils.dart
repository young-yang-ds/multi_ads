import '../../multi_ads.dart';
import '../google_ads/google_ads_service/google_open_ad.dart';
import '../pangle_global/splash_ad.dart';
import 'init_utils.dart';
import 'log_utils.dart';

class OpenUtils {
  static PangleSplashAd? _pangleSplashAd;

  static void loadAndShow(
    String adUnitId,
    AdPlatform adPlatform, {
    int timeout = 3000,
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdSkippedHandle,
  }) {
    LogUtils.log('Open ad loadAndShow, adPlatform: $adPlatform', tag: 'open');

    if (adPlatform == AdPlatform.google) {
      GoogleOpenAd.loadAndShow(
        adUnitId,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
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
          onAdFailedToShowHandle?.call();
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
    }
  }

  static void dispose() {
    GoogleOpenAd.dispose();
    _pangleSplashAd = null;
  }
}
