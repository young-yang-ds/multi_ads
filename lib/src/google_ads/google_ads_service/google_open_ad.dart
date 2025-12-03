import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/log_utils.dart';

class GoogleOpenAd {
  static AppOpenAd? _appOpenAd;
  static bool _isShowingAd = false;

  static void loadAndShow(
    String adUnitId, {
    Function? onAdShowed,
    Function? onAdFailedToShow,
    Function? onAdDismiss,
    Function? onAdClicked,
  }) {
    if (_isShowingAd) return;
    LogUtils.log('Open ad loading', tag: 'google ads');

    AppOpenAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdShowedFullScreenContent: (ad) {
              onAdShowed?.call();
              _isShowingAd = true;

              LogUtils.log('Open ad showed', tag: 'google ads');
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              onAdFailedToShow?.call();
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;

              LogUtils.log('Open ad failed show: $error', tag: 'google ads');
            },
            onAdDismissedFullScreenContent: (ad) {
              onAdDismiss?.call();
              _isShowingAd = false;
              ad.dispose();
              _appOpenAd = null;

              LogUtils.log('Open ad dismiss', tag: 'google ads');
            },
            onAdClicked: (ad) {
              onAdClicked?.call();
            },
          );
          _appOpenAd?.show();
        },
        onAdFailedToLoad: (error) {
          onAdFailedToShow?.call();

          LogUtils.log('Open ad load failed: $error', tag: 'google ads');
        },
      ),
    );
  }

  static void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
  }
}
