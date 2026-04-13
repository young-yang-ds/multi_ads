import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;

import '../../multi_ads.dart';
import 'log_utils.dart';

/// Unified utility for loading and displaying native ads across platforms.
///
/// Currently supports Google AdMob native ads.
/// Can be extended to support other platforms in the future.
class NativeUtils {
  static AdPlatform _currentAdPlatform = AdPlatform.google;
  static bool _isAdLoaded = false;

  /// Load a native ad
  ///
  /// [adUnitId] - The ad unit ID
  /// [adPlatform] - The ad platform to use
  /// [style] - Google only. Custom style config for factory mode.
  /// [templateType] - Google only. Template size: small or medium (default).
  static void load(
    String adUnitId,
    AdPlatform adPlatform, {
    NativeAdStyle? style,
    TemplateType templateType = TemplateType.medium,
    NativeTemplateStyle? nativeTemplateStyle,
    Function? onAdLoadedRefresh,
    Function(AdError error)? onAdFailedToLoadHandle,
    Function? onAdClickedHandle,
  }) {
    _currentAdPlatform = adPlatform;
    _isAdLoaded = false;

    LogUtils.log(
      'Native ad load, adPlatform: $adPlatform',
      tag: 'native',
    );

    if (adPlatform == AdPlatform.google) {
      GoogleNativeAd.load(
        adUnitId,
        style: style,
        templateType: templateType,
        nativeTemplateStyle: nativeTemplateStyle,
        onAdLoadedRefresh: () {
          _isAdLoaded = true;
          onAdLoadedRefresh?.call();
        },
        onAdFailedToLoadHandle: (code, message) {
          _isAdLoaded = false;
          onAdFailedToLoadHandle?.call(
            AdError(code: code, message: message, platform: 'google'),
          );
        },
        onAdClickedHandle: () {
          onAdClickedHandle?.call();
        },
      );
    }
  }

  /// Build the native ad widget
  ///
  /// Returns [SizedBox.shrink] if the ad is not loaded.
  static Widget buildWidget() {
    if (!_isAdLoaded) {
      return const SizedBox.shrink();
    }

    if (_currentAdPlatform == AdPlatform.google) {
      return GoogleNativeAd.buildWidget();
    }

    return const SizedBox.shrink();
  }

  /// Dispose the native ad and release resources
  static void dispose() {
    if (_currentAdPlatform == AdPlatform.google) {
      GoogleNativeAd.dispose();
    }
    _isAdLoaded = false;
  }

  /// Whether the native ad is currently loaded
  static bool get isLoaded => _isAdLoaded;
}
