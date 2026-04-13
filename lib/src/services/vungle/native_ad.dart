import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:multi_ads/src/models/native_ad_style.dart';
import 'package:multi_ads/src/utils/log_utils.dart';
import 'models/vungle_ad_error.dart';
import 'vungle_method_channel.dart';

/// Vungle Native Ad
class VungleNativeAd {
  static const MethodChannel _channel = MethodChannel('multi_ads/vungle');
  static const EventChannel _eventChannel =
      EventChannel('multi_ads/vungle/native_events');

  static bool _isLoaded = false;
  static bool _isLoading = false;
  static NativeAdStyle _style = const NativeAdStyle();
  static String _placementId = '';

  static Function()? _onAdLoaded;
  static Function(VungleAdError error)? _onAdLoadFailed;
  static Function()? _onAdClicked;
  static Function()? _onAdImpression;

  static bool _eventListenerSetup = false;

  static void _setupEventListener() {
    if (_eventListenerSetup) return;
    _eventListenerSetup = true;

    _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
      final String eventType = data['event'] as String;
      final String eventPlacementId = data['placementId'] as String? ?? '';

      if (eventPlacementId != _placementId) return;

      vungleLog('[VungleNativeAd] Event received: $eventType');
      LogUtils.log('Event received: $eventType', tag: 'VungleNativeAd');

      switch (eventType) {
        case 'onAdLoaded':
          _isLoading = false;
          _isLoaded = true;
          vungleLog('[VungleNativeAd] Ad loaded');
          LogUtils.log('Ad loaded', tag: 'VungleNativeAd');
          _onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          _isLoading = false;
          _isLoaded = false;
          final error = VungleAdError.fromJson(
            Map<String, dynamic>.from(data['error'] ?? {}),
          );
          vungleLog(
            '[VungleNativeAd] Ad load failed: ${error.code} - ${error.message}',
          );
          LogUtils.log('Ad load failed: ${error.code} - ${error.message}', tag: 'VungleNativeAd');
          _onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          vungleLog('[VungleNativeAd] Ad clicked');
          LogUtils.log('Ad clicked', tag: 'VungleNativeAd');
          _onAdClicked?.call();
          break;
        case 'onAdImpression':
          vungleLog('[VungleNativeAd] Ad impression');
          LogUtils.log('Ad impression', tag: 'VungleNativeAd');
          _onAdImpression?.call();
          break;
      }
    });
  }

  /// Load a Vungle native ad
  static Future<bool> load(
    String placementId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(VungleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdImpression,
  }) async {
    if (_isLoading) return false;
    if (_isLoaded) return true;

    _setupEventListener();

    _isLoading = true;
    _placementId = placementId;
    _style = style ?? const NativeAdStyle();
    _onAdLoaded = onAdLoaded;
    _onAdLoadFailed = onAdLoadFailed;
    _onAdClicked = onAdClicked;
    _onAdImpression = onAdImpression;

    vungleLog('[VungleNativeAd] Loading ad for placement: $placementId');
    LogUtils.log('Loading ad for placement: $placementId', tag: 'VungleNativeAd');

    try {
      final result = await _channel.invokeMethod<bool>('loadNativeAd', {
        'placementId': placementId,
        'style': _style.toMap(),
      });
      return result ?? false;
    } catch (e) {
      _isLoading = false;
      vungleLog('[VungleNativeAd] Load error: $e');
      LogUtils.log('Load error: $e', tag: 'VungleNativeAd');
      onAdLoadFailed?.call(VungleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  /// Build the native ad widget
  static Widget buildWidget() {
    if (!_isLoaded) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> creationParams = {
      'placementId': _placementId,
      'style': _style.toMap(),
    };

    Widget platformView;

    if (defaultTargetPlatform == TargetPlatform.android) {
      platformView = PlatformViewLink(
        viewType: 'multi_ads/vungle/native',
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
            id: params.id,
            viewType: 'multi_ads/vungle/native',
            layoutDirection: TextDirection.ltr,
            creationParams: creationParams,
            creationParamsCodec: const StandardMessageCodec(),
            onFocus: () {
              params.onFocusChanged(true);
            },
          )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      platformView = UiKitView(
        viewType: 'multi_ads/vungle/native',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      return const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_style.cornerRadius),
      child: SizedBox(
        width: double.infinity,
        height: _style.height,
        child: platformView,
      ),
    );
  }

  /// Dispose the native ad
  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod('disposeNativeAd', {
        'placementId': _placementId,
      });
    } catch (e) {
      vungleLog('[VungleNativeAd] Dispose error: $e');
    }
    _isLoaded = false;
    _isLoading = false;
    _onAdLoaded = null;
    _onAdLoadFailed = null;
    _onAdClicked = null;
    _onAdImpression = null;
  }

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;
}
