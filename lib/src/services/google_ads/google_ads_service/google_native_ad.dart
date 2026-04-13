import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:multi_ads/src/models/native_ad_style.dart';
import 'package:multi_ads/src/utils/log_utils.dart';

/// Google Native Ad wrapper supporting both custom style and NativeTemplateStyle modes.
///
/// **Custom style mode** (layout built by plugin's NativeAdViewBuilder, styled from Dart):
/// ```dart
/// GoogleNativeAd.load(
///   'your-ad-unit-id',
///   style: NativeAdStyle(height: 80, imageWidth: 120, cornerRadius: 10),
///   onAdLoadedRefresh: () => setState(() {}),
/// );
/// GoogleNativeAd.buildWidget();
/// ```
///
/// **Template mode** (built-in Google template, no native code needed):
/// ```dart
/// GoogleNativeAd.load(
///   'your-ad-unit-id',
///   templateType: TemplateType.small,
///   onAdLoadedRefresh: () => setState(() {}),
/// );
/// GoogleNativeAd.buildWidget();
/// ```
class GoogleNativeAd {
  static NativeAd? _nativeAd;
  static bool _isLoading = false;
  static bool _isLoaded = false;
  static TemplateType _templateType = TemplateType.medium;
  static bool _useFactory = false;
  static NativeAdStyle _style = const NativeAdStyle();

  /// Load a native ad
  ///
  /// If [style] is provided, uses factory mode with customOptions (requires
  /// NativeAdFactory registration in native code, typically a 3-line delegation
  /// to plugin's NativeAdViewBuilder).
  ///
  /// If [style] is null, uses NativeTemplateStyle mode (pure Dart).
  ///
  /// [adUnitId] - The ad unit ID from AdMob console
  /// [style] - Custom style config, passed to native via customOptions
  /// [templateType] - Template size (only for template mode)
  /// [nativeTemplateStyle] - Custom template style (only for template mode)
  /// [request] - Optional custom [AdRequest]
  static void load(
    String adUnitId, {
    NativeAdStyle? style,
    TemplateType templateType = TemplateType.medium,
    NativeTemplateStyle? nativeTemplateStyle,
    AdRequest? request,
    Function? onAdLoadedRefresh,
    Function(int code, String message)? onAdFailedToLoadHandle,
    Function? onAdClickedHandle,
    Function? onAdImpressionHandle,
    Function? onAdOpenedHandle,
    Function? onAdClosedHandle,
  }) {
    if (_isLoading) return;
    if (_nativeAd != null) return;

    _isLoading = true;
    _isLoaded = false;
    _useFactory = style != null;
    _templateType = templateType;
    _style = style ?? const NativeAdStyle();

    final listener = NativeAdListener(
      onAdLoaded: (ad) {
        _isLoading = false;
        _isLoaded = true;
        LogUtils.log('Native ad loaded', tag: 'google ads');
        onAdLoadedRefresh?.call();
      },
      onAdFailedToLoad: (ad, error) {
        _isLoading = false;
        _isLoaded = false;
        ad.dispose();
        _nativeAd = null;
        LogUtils.log('Native ad load failed: $error', tag: 'google ads');
        onAdFailedToLoadHandle?.call(error.code, error.message);
      },
      onAdClicked: (ad) {
        LogUtils.log('Native ad clicked', tag: 'google ads');
        onAdClickedHandle?.call();
      },
      onAdImpression: (ad) {
        LogUtils.log('Native ad impression', tag: 'google ads');
        onAdImpressionHandle?.call();
      },
      onAdOpened: (ad) {
        LogUtils.log('Native ad opened', tag: 'google ads');
        onAdOpenedHandle?.call();
      },
      onAdClosed: (ad) {
        LogUtils.log('Native ad closed', tag: 'google ads');
        onAdClosedHandle?.call();
      },
    );

    if (_useFactory) {
      LogUtils.log('Native ad loading (custom style)', tag: 'google ads');
      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        factoryId: 'multiAdsNativeFactory',
        customOptions: _style.toMap(),
        request: request ?? const AdRequest(),
        listener: listener,
      )..load();
    } else {
      LogUtils.log('Native ad loading (template: $templateType)', tag: 'google ads');
      _nativeAd = NativeAd(
        adUnitId: adUnitId,
        request: request ?? const AdRequest(),
        nativeTemplateStyle: nativeTemplateStyle ??
            NativeTemplateStyle(templateType: templateType),
        listener: listener,
      )..load();
    }
  }

  /// Build the native ad widget
  ///
  /// Returns [SizedBox.shrink] if the ad is not loaded.
  static Widget buildWidget() {
    if (_nativeAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }

    final adWidget = AdWidget(key: ObjectKey(_nativeAd!), ad: _nativeAd!);

    if (_useFactory) {
      return Padding(
        padding: _style.margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_style.cornerRadius),
          child: SizedBox(
            width: double.infinity,
            height: _style.height,
            child: adWidget,
          ),
        ),
      );
    }

    final constraints = _templateType == TemplateType.small
        ? const BoxConstraints(
            minWidth: 320,
            minHeight: 90,
            maxWidth: 400,
            maxHeight: 200,
          )
        : const BoxConstraints(
            minWidth: 320,
            minHeight: 320,
            maxWidth: 400,
            maxHeight: 400,
          );

    return Container(
      color: Colors.white,
      child: ConstrainedBox(
        constraints: constraints,
        child: adWidget,
      ),
    );
  }

  /// Dispose the native ad and release resources
  static void dispose() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoading = false;
    _isLoaded = false;
  }

  /// Whether the native ad is currently loaded and ready to display
  static bool get isLoaded => _isLoaded;

  /// Whether the native ad is currently loading
  static bool get isLoading => _isLoading;
}
