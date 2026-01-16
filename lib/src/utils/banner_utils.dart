import 'package:flutter/material.dart';

import '../../multi_ads.dart';
import '../models/ad_error.dart';

class BannerUtils {
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static String _adUnitId = '';
  static Function(AdError error)? _onAdFailedToShowHandle;
  static Function? _onAdClickedHandle;
  static Function? _onAdLoadedRefresh;
  static Widget? _cachedWidget;
  static bool _isAdLoaded = false;
  static Color? _backgroundColor;

  static Future<void> load(
    BuildContext context,
    String adUnitId,
    AdPlatform adPlatform, {
    Function? onAdShowedHandle,
    Function(AdError error)? onAdFailedToShowHandle,
    Function? onAdDismissHandle,
    Function? onAdClickedHandle,
    Function? onAdLoadedRefresh,
    Color? backgroundColor,
  }) async {
    _currentAdPlatform = adPlatform;
    _adUnitId = adUnitId;
    _onAdFailedToShowHandle = onAdFailedToShowHandle;
    _onAdClickedHandle = onAdClickedHandle;
    _onAdLoadedRefresh = onAdLoadedRefresh;
    _cachedWidget = null;
    _isAdLoaded = false;
    _backgroundColor = backgroundColor;

    if (adPlatform == AdPlatform.google) {
      await GoogleBannerAd.load(
        context,
        adUnitId,
        onAdShowedHandle: onAdShowedHandle,
        onAdFailedToShowHandle: (code, message) {
          _isAdLoaded = false;
          onAdFailedToShowHandle?.call(
            AdError(code: code, message: message, platform: 'google'),
          );
        },
        onAdDismissHandle: onAdDismissHandle,
        onAdClickedHandle: onAdClickedHandle,
        onAdLoadedRefresh: () {
          _isAdLoaded = true;
          onAdLoadedRefresh?.call();
        },
      );
    } else if (adPlatform == AdPlatform.vungle) {
      _isAdLoaded = true;
      onAdLoadedRefresh?.call();
    }
  }

  static Widget buildWidget({Color? backgroundColor}) {
    final bgColor = backgroundColor ?? _backgroundColor;

    if (_currentAdPlatform == AdPlatform.google && !_isAdLoaded) {
      return const SizedBox.shrink();
    }

    if (_cachedWidget != null && backgroundColor == null) {
      return _cachedWidget!;
    }

    Widget? widget;
    if (_currentAdPlatform == AdPlatform.google) {
      widget = GoogleBannerAd.buildWidget();
    } else if (_currentAdPlatform == AdPlatform.pangleGlobal) {
      widget = PangleBannerAdWidget(
        slotId: _adUnitId,
        adSize: BannerAdSize.anchoredAdaptive,
        onAdLoaded: () {
          _onAdLoadedRefresh?.call();
        },
        onAdLoadFailed: (PangleAdError error) {
          _onAdFailedToShowHandle?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'pangle',
            ),
          );
        },
        onAdClicked: () {
          _onAdClickedHandle?.call();
        },
      );
    } else if (_currentAdPlatform == AdPlatform.vungle) {
      widget = VungleBannerAdWidget(
        placementId: _adUnitId,
        adSize: VungleBannerAdSize.banner,
        backgroundColor: bgColor,
        onAdLoaded: () {
          _isAdLoaded = true;
          _onAdLoadedRefresh?.call();
        },
        onAdLoadFailed: (VungleAdError error) {
          _isAdLoaded = false;
          _onAdFailedToShowHandle?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'vungle',
            ),
          );
        },
        onAdClicked: () {
          _onAdClickedHandle?.call();
        },
      );
    }

    if (backgroundColor == null) {
      _cachedWidget = widget;
    }

    return widget ?? const SizedBox.shrink();
  }

  static void dispose() {
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleBannerAd.dispose();
    }
    _adUnitId = '';
    _onAdFailedToShowHandle = null;
    _onAdClickedHandle = null;
    _onAdLoadedRefresh = null;
    _cachedWidget = null;
    _isAdLoaded = false;
    _backgroundColor = null;
  }
}
