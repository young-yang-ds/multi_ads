import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../utils/log_utils.dart';

class GoogleInterstitialAd {
  static InterstitialAd? _interstitialAd;
  static bool _isLoading = false;

  static void load(
    String adUnitId, {
    Function? onAdLoadedHandle,
    Function(int code, String message)? onAdFailedToLoadHandle,
  }) {
    if (_isLoading) return;
    _isLoading = true;

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _isLoading = false;
          _interstitialAd = ad;
          onAdLoadedHandle?.call();
          LogUtils.log('Inter ad loaded', tag: 'google ads');
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isLoading = false;
          onAdFailedToLoadHandle?.call(error.code, error.message);
          LogUtils.log('Inter ad load failed: $error', tag: 'google ads');
        },
      ),
    );
  }

  static void show({
    Function? onAdShowedHandle,
    Function(int code, String message)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (_interstitialAd == null) {
      onAdFailedToShowHandle?.call(-1, 'Ad not loaded');
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        onAdShowedHandle?.call();
        LogUtils.log('Inter ad showed', tag: 'google ads');
      },
      onAdFailedToShowFullScreenContent: (ad, err) {
        onAdFailedToShowHandle?.call(err.code, err.message);
        ad.dispose();
        _interstitialAd = null;
        LogUtils.log('Inter ad failed show: $err', tag: 'google ads');
      },
      onAdDismissedFullScreenContent: (ad) {
        onAdDismissHandle?.call();
        ad.dispose();
        _interstitialAd = null;
        LogUtils.log('Inter ad dismiss', tag: 'google ads');
      },
      onAdImpression: (ad) {
        onAdImpressionHandle?.call();
      },
      onAdClicked: (ad) {
        onAdClickedHandle?.call();
      },
    );

    _interstitialAd!.show();
  }

  static void dispose() {
    _isLoading = false;
    _interstitialAd?.dispose();
    _interstitialAd = null;
  }

  static bool get isLoaded => _interstitialAd != null;
}
