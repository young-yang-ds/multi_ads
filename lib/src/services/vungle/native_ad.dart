import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:multi_ads/src/models/native_ad_style.dart';
import 'package:multi_ads/src/utils/log_utils.dart';
import 'models/vungle_ad_error.dart';
import 'vungle_method_channel.dart';

final Set<Factory<OneSequenceGestureRecognizer>> _tapGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(() => TapGestureRecognizer()),
    };

/// Vungle Native Ad - multi-instance supported.
///
/// Each call to [VungleNativeAd.create] produces a new instance with its own
/// `listenerId`. Native side keeps a `[listenerId: Manager]` dictionary so
/// multiple ads can coexist even with the same `placementId`.
///
/// Legacy static API (`load` / `buildWidget` / `dispose`) is retained for
/// backwards compatibility and operates on a default singleton instance.
class VungleNativeAd {
  static const MethodChannel _channel = MethodChannel('multi_ads/vungle');
  static const EventChannel _eventChannel = EventChannel(
    'multi_ads/vungle/native_events',
  );

  // ── Global event dispatcher ────────────────────────────────────────────

  static bool _globalListenerSetup = false;
  static final Map<String, VungleNativeAd> _instances = {};
  static int _idCounter = 0;

  static void _setupGlobalListener() {
    if (_globalListenerSetup) return;
    _globalListenerSetup = true;

    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
          final String eventType = data['event'] as String? ?? '';
          final String listenerId = data['listenerId'] as String? ?? '';

          final instance = _instances[listenerId];
          if (instance == null) return;

          instance._handleEvent(eventType, data);
        } catch (e) {
          LogUtils.log('Event handling error: $e', tag: 'VungleNativeAd');
        }
      },
      onError: (error) {
        LogUtils.log('Event stream error: $error', tag: 'VungleNativeAd');
      },
    );
  }

  // ── Instance ───────────────────────────────────────────────────────────

  final String listenerId;
  String _placementId = '';
  NativeAdStyle _style = const NativeAdStyle();
  bool _isLoaded = false;
  bool _isLoading = false;

  Function()? _onAdLoaded;
  Function(VungleAdError error)? _onAdLoadFailed;
  Function()? _onAdClicked;
  Function()? _onAdImpression;
  ValueChanged<int>? _onAdSwipe;

  VungleNativeAd._internal(this.listenerId);

  /// Create a new multi-instance Vungle native ad.
  factory VungleNativeAd.create() {
    final id =
        'vungle_native_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
    final inst = VungleNativeAd._internal(id);
    _instances[id] = inst;
    _setupGlobalListener();
    return inst;
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  void _handleEvent(String eventType, Map<dynamic, dynamic> data) {
    vungleLog('[VungleNativeAd][$listenerId] Event received: $eventType');
    LogUtils.log('Event [$listenerId]: $eventType', tag: 'VungleNativeAd');

    switch (eventType) {
      case 'onAdLoaded':
        _isLoading = false;
        _isLoaded = true;
        _onAdLoaded?.call();
        break;
      case 'onAdLoadFailed':
        _isLoading = false;
        _isLoaded = false;
        final error = VungleAdError.fromJson(
          Map<String, dynamic>.from(data['error'] ?? {}),
        );
        _onAdLoadFailed?.call(error);
        break;
      case 'onAdClicked':
        _onAdClicked?.call();
        break;
      case 'onAdImpression':
        _onAdImpression?.call();
        break;
      case 'onAdSwipe':
        final direction = data['direction'];
        if (direction is int && direction != 0) {
          _onAdSwipe?.call(direction);
        }
        break;
    }
  }

  /// Load this instance's ad.
  Future<bool> loadAd(
    String placementId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(VungleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdImpression,
    ValueChanged<int>? onAdSwipe,
  }) async {
    if (_isLoading) return false;
    if (_isLoaded) return true;

    _isLoading = true;
    _placementId = placementId;
    _style = style ?? const NativeAdStyle();
    _onAdLoaded = onAdLoaded;
    _onAdLoadFailed = onAdLoadFailed;
    _onAdClicked = onAdClicked;
    _onAdImpression = onAdImpression;
    _onAdSwipe = onAdSwipe;

    vungleLog(
      '[VungleNativeAd][$listenerId] Loading ad for placement: $placementId',
    );
    LogUtils.log(
      'Loading [$listenerId] placement: $placementId',
      tag: 'VungleNativeAd',
    );

    try {
      final result = await _channel.invokeMethod<bool>('loadNativeAd', {
        'listenerId': listenerId,
        'placementId': placementId,
        'style': _style.toMap(),
      });
      return result ?? false;
    } catch (e) {
      _isLoading = false;
      vungleLog('[VungleNativeAd][$listenerId] Load error: $e');
      LogUtils.log('Load error [$listenerId]: $e', tag: 'VungleNativeAd');
      onAdLoadFailed?.call(VungleAdError(code: -1, message: e.toString()));
      return false;
    }
  }

  /// Build the native ad widget for this instance.
  Widget buildAdWidget() {
    if (!_isLoaded) {
      return const SizedBox.shrink();
    }

    final Map<String, dynamic> creationParams = {
      'listenerId': listenerId,
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
            gestureRecognizers: _tapGestureRecognizers,
            hitTestBehavior: PlatformViewHitTestBehavior.translucent,
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
        gestureRecognizers: _tapGestureRecognizers,
        hitTestBehavior: PlatformViewHitTestBehavior.translucent,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: _style.margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_style.cornerRadius),
        child: SizedBox(
          width: double.infinity,
          height: _style.height,
          child: platformView,
        ),
      ),
    );
  }

  /// Dispose this instance.
  Future<void> disposeAd() async {
    try {
      await _channel.invokeMethod('disposeNativeAd', {
        'listenerId': listenerId,
      });
    } catch (e) {
      vungleLog('[VungleNativeAd][$listenerId] Dispose error: $e');
    }
    _isLoaded = false;
    _isLoading = false;
    _onAdLoaded = null;
    _onAdLoadFailed = null;
    _onAdClicked = null;
    _onAdImpression = null;
    _onAdSwipe = null;
    _instances.remove(listenerId);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Legacy static API (backwards compatibility) ──────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  static VungleNativeAd? _defaultInstance;

  static VungleNativeAd _ensureDefault() {
    return _defaultInstance ??= VungleNativeAd.create();
  }

  /// Legacy: load a native ad using the default singleton instance.
  static Future<bool> load(
    String placementId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(VungleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdImpression,
    ValueChanged<int>? onAdSwipe,
  }) {
    // Dispose any stale instance so the same slot can be reloaded.
    final existing = _defaultInstance;
    if (existing != null) {
      existing.disposeAd();
      _defaultInstance = null;
    }
    final inst = _ensureDefault();
    return inst.loadAd(
      placementId,
      style: style,
      onAdLoaded: onAdLoaded,
      onAdLoadFailed: onAdLoadFailed,
      onAdClicked: onAdClicked,
      onAdImpression: onAdImpression,
      onAdSwipe: onAdSwipe,
    );
  }

  /// Legacy: build widget for the default singleton instance.
  static Widget buildWidget() {
    final inst = _defaultInstance;
    if (inst == null) return const SizedBox.shrink();
    return inst.buildAdWidget();
  }

  /// Legacy: dispose the default singleton instance.
  static Future<void> dispose() async {
    final inst = _defaultInstance;
    if (inst == null) return;
    await inst.disposeAd();
    _defaultInstance = null;
  }
}
