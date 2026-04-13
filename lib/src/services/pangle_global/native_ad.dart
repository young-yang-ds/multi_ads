import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:multi_ads/src/models/native_ad_style.dart';
import 'package:multi_ads/src/utils/log_utils.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';

/// Pangle Global Native Ad
class PangleNativeAd {
  static const MethodChannel _channel =
      MethodChannel('multi_ads/pangle_global');
  static const EventChannel _eventChannel =
      EventChannel('multi_ads/pangle_global/native_events');

  static bool _isLoaded = false;
  static bool _isLoading = false;
  static NativeAdStyle _style = const NativeAdStyle();
  static String _slotId = '';

  static Function()? _onAdLoaded;
  static Function(PangleAdError error)? _onAdLoadFailed;
  static Function()? _onAdClicked;
  static Function()? _onAdShowed;

  static bool _eventListenerSetup = false;

  static void _setupEventListener() {
    if (_eventListenerSetup) return;
    _eventListenerSetup = true;

    _eventChannel.receiveBroadcastStream().listen((event) {
      final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
      final String eventType = data['event'] as String;
      pangleLog('[PangleNativeAd] Event received: $eventType');
      LogUtils.log('Event received: $eventType', tag: 'PangleNativeAd');

      switch (eventType) {
        case 'onAdLoaded':
          _isLoading = false;
          _isLoaded = true;
          pangleLog('[PangleNativeAd] Ad loaded');
          LogUtils.log('Ad loaded', tag: 'PangleNativeAd');
          _onAdLoaded?.call();
          break;
        case 'onAdLoadFailed':
          _isLoading = false;
          _isLoaded = false;
          final error =
              PangleAdError.fromJson(Map<String, dynamic>.from(data['error']));
          pangleLog(
              '[PangleNativeAd] Ad load failed: ${error.code} - ${error.message}');
          LogUtils.log('Ad load failed: ${error.code} - ${error.message}', tag: 'PangleNativeAd');
          _onAdLoadFailed?.call(error);
          break;
        case 'onAdClicked':
          pangleLog('[PangleNativeAd] Ad clicked');
          LogUtils.log('Ad clicked', tag: 'PangleNativeAd');
          _onAdClicked?.call();
          break;
        case 'onAdShowed':
          pangleLog('[PangleNativeAd] Ad showed');
          LogUtils.log('Ad showed', tag: 'PangleNativeAd');
          _onAdShowed?.call();
          break;
      }
    });
  }

  /// Load a Pangle native ad
  static Future<bool> load(
    String slotId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(PangleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdShowed,
  }) async {
    if (_isLoading) return false;
    if (_isLoaded) return true;

    _setupEventListener();

    _isLoading = true;
    _slotId = slotId;
    _style = style ?? const NativeAdStyle();
    _onAdLoaded = onAdLoaded;
    _onAdLoadFailed = onAdLoadFailed;
    _onAdClicked = onAdClicked;
    _onAdShowed = onAdShowed;

    pangleLog('[PangleNativeAd] Loading ad with slotId: $slotId');
    LogUtils.log('Loading ad with slotId: $slotId', tag: 'PangleNativeAd');

    try {
      final result = await _channel.invokeMethod<bool>('loadNativeAd', {
        'slotId': slotId,
        'style': _style.toMap(),
      });
      return result ?? false;
    } catch (e) {
      _isLoading = false;
      pangleLog('[PangleNativeAd] Load error: $e');
      LogUtils.log('Load error: $e', tag: 'PangleNativeAd');
      onAdLoadFailed?.call(PangleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  /// Build the native ad widget
  static Widget buildWidget() {
    if (!_isLoaded) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> creationParams = {
      'slotId': _slotId,
      'style': _style.toMap(),
    };

    Widget platformView;

    if (defaultTargetPlatform == TargetPlatform.android) {
      platformView = PlatformViewLink(
        viewType: 'multi_ads/pangle_global/native',
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
            viewType: 'multi_ads/pangle_global/native',
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
        viewType: 'multi_ads/pangle_global/native',
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
      await _channel.invokeMethod('disposeNativeAd');
    } catch (e) {
      pangleLog('[PangleNativeAd] Dispose error: $e');
    }
    _isLoaded = false;
    _isLoading = false;
    _onAdLoaded = null;
    _onAdLoadFailed = null;
    _onAdClicked = null;
    _onAdShowed = null;
  }

  static bool get isLoaded => _isLoaded;
  static bool get isLoading => _isLoading;
}
