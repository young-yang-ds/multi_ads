import '../../multi_ads.dart';
import '../google_ads/google_ads_service/google_interstitial_ad.dart';
import '../models/ad_error.dart';
import '../pangle_global/interstitial_ad.dart';
import '../vungle/interstitial_ad.dart';
import 'log_utils.dart';

class InterstitialUtils {
  static bool _isLooping = false;
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static PangleInterstitialAd? _pangleAd;
  static VungleInterstitialAd? _vungleAd;

  static void start(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Future<bool?> Function()? onOtherShowHandle,
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
      onOtherShowHandle: onOtherShowHandle,
    );
  }

  static void stop() {
    _isLooping = false;
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleInterstitialAd.dispose();
    } else if (_currentAdPlatform == AdPlatform.pangleGlobal) {
      _pangleAd = null;
    } else if (_currentAdPlatform == AdPlatform.vungle) {
      _vungleAd = null;
    }
  }

  /// Manually trigger interstitial ad load and show (one-time)
  static Future<void> showOnce(
    String adUnitId,
    AdPlatform adPlatform, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
  }) async {
    if (adPlatform == AdPlatform.google) {
      GoogleInterstitialAd.load(
        adUnitId,
        onAdLoadedHandle: () {
          GoogleInterstitialAd.show(
            onAdShowedHandle: onAdShowedHandle,
            onAdFailedToShowHandle: (code, message) {
              onAdFailedToShowHandle?.call(
                AdError(code: code, message: message, platform: 'google'),
              );
            },
            onAdDismissHandle: () {
              onAdDismissHandle?.call();
            },
            onAdClickedHandle: onAdClickedHandle,
            onAdImpressionHandle: onAdImpressionHandle,
          );
        },
        onAdFailedToLoadHandle: (code, message) {
          onAdFailedToShowHandle?.call(
            AdError(code: code, message: message, platform: 'google'),
          );
        },
      );
    } else if (adPlatform == AdPlatform.pangleGlobal) {
      late PangleInterstitialAd pangleAd;
      pangleAd = PangleInterstitialAd(
        slotId: adUnitId,
        onAdLoaded: () {
          pangleAd.show();
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
        onAdShowed: () {
          onAdShowedHandle?.call();
        },
        onAdDismissed: () {
          onAdDismissHandle?.call();
        },
        onAdClicked: () {
          onAdClickedHandle?.call();
        },
      );
      pangleAd.load();
    } else if (adPlatform == AdPlatform.vungle) {
      late VungleInterstitialAd vungleAd;
      vungleAd = VungleInterstitialAd(
        placementId: adUnitId,
        onAdLoaded: () {
          vungleAd.show();
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
        onAdDismissed: () {
          onAdDismissHandle?.call();
        },
        onAdClicked: () {
          onAdClickedHandle?.call();
        },
        onAdImpression: () {
          onAdImpressionHandle?.call();
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
      vungleAd.load();
    }
  }

  static Future<void> _loadAndShow(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Future<bool?> Function()? onOtherShowHandle,
  }) async {
    if (!_isLooping) return;

    // Check if should skip this ad load
    if (onOtherShowHandle != null) {
      final shouldSkip = await onOtherShowHandle();
      if (shouldSkip == true) {
        _scheduleNext(
          adUnitId,
          adPlatform,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
          onOtherShowHandle: onOtherShowHandle,
        );
        return;
      }
    }

    if (adPlatform == AdPlatform.google) {
      _loadAndShowGoogle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
        onOtherShowHandle: onOtherShowHandle,
      );
    } else if (adPlatform == AdPlatform.pangleGlobal) {
      _loadAndShowPangle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onOtherShowHandle: onOtherShowHandle,
      );
    } else if (adPlatform == AdPlatform.vungle) {
      _loadAndShowVungle(
        adUnitId,
        displayInterval,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: onAdFailedToShowHandle,
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdImpressionHandle: onAdImpressionHandle,
        onOtherShowHandle: onOtherShowHandle,
      );
    }
  }

  static void _loadAndShowGoogle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Future<bool?> Function()? onOtherShowHandle,
  }) {
    GoogleInterstitialAd.load(
      adUnitId,
      onAdLoadedHandle: () {
        GoogleInterstitialAd.show(
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: (code, message) {
            onAdFailedToShowHandle?.call(
              AdError(code: code, message: message, platform: 'google'),
            );
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
      onAdFailedToLoadHandle: (code, message) {
        onAdFailedToShowHandle?.call(
          AdError(code: code, message: message, platform: 'google'),
        );
        _scheduleNext(
          adUnitId,
          AdPlatform.google,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
          onOtherShowHandle: onOtherShowHandle,
        );
      },
    );
  }

  static void _loadAndShowPangle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Future<bool?> Function()? onOtherShowHandle,
  }) {
    _pangleAd = PangleInterstitialAd(
      slotId: adUnitId,
      onAdLoaded: () {
        _pangleAd?.show();
      },
      onAdLoadFailed: (error) {
        onAdFailedToShowHandle?.call(
          AdError(code: error.code, message: error.message, platform: 'pangle'),
        );
        _scheduleNext(
          adUnitId,
          AdPlatform.pangleGlobal,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onOtherShowHandle: onOtherShowHandle,
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
          onOtherShowHandle: onOtherShowHandle,
        );
      },
      onAdClicked: () {
        onAdClickedHandle?.call();
      },
    );
    _pangleAd?.load();
  }

  static void _loadAndShowVungle(
    String adUnitId,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Future<bool?> Function()? onOtherShowHandle,
  }) {
    _vungleAd = VungleInterstitialAd(
      placementId: adUnitId,
      onAdLoaded: () {
        _vungleAd?.show();
      },
      onAdLoadFailed: (error) {
        onAdFailedToShowHandle?.call(
          AdError(code: error.code, message: error.message, platform: 'vungle'),
        );
        _scheduleNext(
          adUnitId,
          AdPlatform.vungle,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
          onOtherShowHandle: onOtherShowHandle,
        );
      },
      onAdShowed: () {
        onAdShowedHandle?.call();
      },
      onAdDismissed: () {
        onAdDismissHandle?.call();
        _scheduleNext(
          adUnitId,
          AdPlatform.vungle,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
          onOtherShowHandle: onOtherShowHandle,
        );
      },
      onAdClicked: () {
        onAdClickedHandle?.call();
      },
      onAdImpression: () {
        onAdImpressionHandle?.call();
      },
      onAdFailedToPlay: (error) {
        onAdFailedToShowHandle?.call(
          AdError(code: error.code, message: error.message, platform: 'vungle'),
        );
        _scheduleNext(
          adUnitId,
          AdPlatform.vungle,
          displayInterval,
          onAdShowedHandle: onAdShowedHandle,
          onAdFailedToShowHandle: onAdFailedToShowHandle,
          onAdDismissHandle: onAdDismissHandle,
          onAdClickedHandle: onAdClickedHandle,
          onAdImpressionHandle: onAdImpressionHandle,
          onOtherShowHandle: onOtherShowHandle,
        );
      },
    );
    _vungleAd?.load();
  }

  static void _scheduleNext(
    String adUnitId,
    AdPlatform adPlatform,
    int displayInterval, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Future<bool?> Function()? onOtherShowHandle,
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
        onOtherShowHandle: onOtherShowHandle,
      );
    });
  }
}
