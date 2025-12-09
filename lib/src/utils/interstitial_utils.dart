import '../../multi_ads.dart';
import '../google_ads/google_ads_service/google_interstitial_ad.dart';
import '../pangle_global/interstitial_ad.dart';
import 'init_utils.dart';
import 'log_utils.dart';

class InterstitialUtils {
  static bool _isLooping = false;
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static PangleInterstitialAd? _pangleAd;

  static void start(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (_isLooping) return;
    LogUtils.log(
      'Inter ad start, adPlatform: $adPlatform',
      tag: 'interstitial',
    );

    _isLooping = true;
    _currentAdPlatform = adPlatform;
    _loadAndShow(
      adUnitId,
      adPlatform,
      displayInterval,
      onAdShowedHandle: onAdShowedHandle,
      onAdFailedToShowHandle: onAdFailedToShowHandle,
      onAdDismissHandle: onAdDismissHandle,
      onAdClickedHandle: onAdClickedHandle,
      onAdImpressionHandle: onAdImpressionHandle,
    );
  }

  static void stop() {
    _isLooping = false;
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleInterstitialAd.dispose();
    } else if (_currentAdPlatform == AdPlatform.pangleGlobal) {
      _pangleAd = null;
    }
  }

  static void _loadAndShow(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (!_isLooping) return;

    if (adPlatform == AdPlatform.google) {
      _loadAndShowGoogle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
      );
    } else if (adPlatform == AdPlatform.pangleGlobal) {
      _loadAndShowPangle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
      );
    }
  }

  static void _loadAndShowGoogle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    GoogleInterstitialAd.load(
      adUnitId,
      onAdLoadedHandle: () {
        GoogleInterstitialAd.show(
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: () {
            onAdFailedToShowHandle?.call();
            _scheduleNext(
              adUnitId,
              AdPlatform.google,
              displayInterval,
              onAdShowedHandle: onAdShowedHandle,
              onAdFailedToShowHandle: onAdFailedToShowHandle,
              onAdDismissHandle: onAdDismissHandle,
              onAdClickedHandle: onAdClickedHandle,
              onAdImpressionHandle: onAdImpressionHandle,
            );
          },
          onAdDismissHandle: () {
            onAdDismissHandle?.call();
            _scheduleNext(
              adUnitId,
              AdPlatform.google,
              displayInterval,
              onAdShowedHandle: onAdShowedHandle,
              onAdFailedToShowHandle: onAdFailedToShowHandle,
              onAdDismissHandle: onAdDismissHandle,
              onAdClickedHandle: onAdClickedHandle,
              onAdImpressionHandle: onAdImpressionHandle,
            );
          },
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
        );
      },
      onAdFailedToLoadHandle: () {
        onAdFailedToShowHandle?.call();
        _scheduleNext(
          adUnitId,
          AdPlatform.google,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
        );
      },
    );
  }

  static void _loadAndShowPangle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
  }) {
    _pangleAd = PangleInterstitialAd(
      slotId: adUnitId,
      onAdLoaded: () {
        _pangleAd?.show();
      },
      onAdLoadFailed: (error) {
        onAdFailedToShowHandle?.call();
        _scheduleNext(
          adUnitId,
          AdPlatform.pangleGlobal,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
        );
      },
      onAdShowed: () {
        onAdShowedHandle?.call();
      },
      onAdDismissed: () {
        onAdDismissHandle?.call();
        _scheduleNext(
          adUnitId,
          AdPlatform.pangleGlobal,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
        );
      },
      onAdClicked: () {
        onAdClickedHandle?.call();
      },
    );
    _pangleAd?.load();
  }

  static void _scheduleNext(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) {
    if (!_isLooping) return;
    Future.delayed(Duration(seconds: displayInterval), () {
      _loadAndShow(
        adUnitId,
        adPlatform,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
      );
    });
  }
}
