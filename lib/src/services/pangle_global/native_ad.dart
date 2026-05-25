import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:multi_ads/src/models/native_ad_style.dart';
import 'package:multi_ads/src/utils/log_utils.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';

final Set<Factory<OneSequenceGestureRecognizer>> _tapGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(() => TapGestureRecognizer()),
    };

/// Pangle Global Native Ad
///
/// Supports multiple simultaneous instances. Each instance has its own
/// [listenerId] to distinguish events coming through the shared EventChannel.
class PangleNativeAd {
  static const MethodChannel _channel = MethodChannel(
    'multi_ads/pangle_global',
  );
  static const EventChannel _eventChannel = EventChannel(
    'multi_ads/pangle_global/native_events',
  );

  // ── Global event dispatcher ─────────────────────────────────────────────
  static bool _globalListenerSetup = false;
  static final Map<String, PangleNativeAd> _instances = {};
  static int _idCounter = 0;

  static void _setupGlobalListener() {
    if (_globalListenerSetup) return;
    _globalListenerSetup = true;

    _eventChannel.receiveBroadcastStream().listen(
      (event) {
        try {
          final Map<dynamic, dynamic> data = event as Map<dynamic, dynamic>;
          final String listenerId = data['listenerId'] as String? ?? '';
          final String eventType = data['event'] as String? ?? '';
          pangleLog(
            '[PangleNativeAd] Event received: $eventType (listenerId=$listenerId)',
          );

          final instance = _instances[listenerId];
          if (instance == null) {
            LogUtils.log(
              'Event for unknown listenerId=$listenerId dropped ($eventType)',
              tag: 'PangleNativeAd',
            );
            return;
          }
          instance._handleEvent(eventType, data);
        } catch (e) {
          LogUtils.log('Event handling error: $e', tag: 'PangleNativeAd');
        }
      },
      onError: (error) {
        LogUtils.log('Event stream error: $error', tag: 'PangleNativeAd');
      },
    );
  }

  // ── Instance state ──────────────────────────────────────────────────────
  final String listenerId;

  bool _isLoaded = false;
  bool _isLoading = false;
  NativeAdStyle _style = const NativeAdStyle();
  String _slotId = '';

  Function()? _onAdLoaded;
  Function(PangleAdError error)? _onAdLoadFailed;
  Function()? _onAdClicked;
  Function()? _onAdShowed;
  ValueChanged<int>? _onAdSwipe;

  PangleNativeAd._internal(this.listenerId);

  /// Create a new native ad instance.
  factory PangleNativeAd.create() {
    final id =
        'pangle_native_${DateTime.now().microsecondsSinceEpoch}_${_idCounter++}';
    final inst = PangleNativeAd._internal(id);
    _instances[id] = inst;
    _setupGlobalListener();
    return inst;
  }

  void _handleEvent(String eventType, Map<dynamic, dynamic> data) {
    switch (eventType) {
      case 'onAdLoaded':
        _isLoading = false;
        _isLoaded = true;
        LogUtils.log('Ad loaded ($listenerId)', tag: 'PangleNativeAd');
        _onAdLoaded?.call();
        break;
      case 'onAdLoadFailed':
        _isLoading = false;
        _isLoaded = false;
        final error = PangleAdError.fromJson(
          Map<String, dynamic>.from(data['error'] ?? {}),
        );
        LogUtils.log(
          'Ad load failed ($listenerId): ${error.code} - ${error.message}',
          tag: 'PangleNativeAd',
        );
        _onAdLoadFailed?.call(error);
        break;
      case 'onAdClicked':
        LogUtils.log('Ad clicked ($listenerId)', tag: 'PangleNativeAd');
        _onAdClicked?.call();
        break;
      case 'onAdShowed':
        LogUtils.log('Ad showed ($listenerId)', tag: 'PangleNativeAd');
        _onAdShowed?.call();
        break;
      case 'onAdSwipe':
        final direction = data['direction'];
        if (direction is int && direction != 0) {
          LogUtils.log(
            'Ad vertical swipe ($listenerId): $direction',
            tag: 'PangleNativeAd',
          );
          _onAdSwipe?.call(direction);
        }
        break;
    }
  }

  /// Load this native ad instance.
  Future<bool> loadAd(
    String slotId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(PangleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdShowed,
    ValueChanged<int>? onAdSwipe,
  }) async {
    if (_isLoading) return false;

    _isLoading = true;
    _isLoaded = false;
    _slotId = slotId;
    _style = style ?? const NativeAdStyle();
    _onAdLoaded = onAdLoaded;
    _onAdLoadFailed = onAdLoadFailed;
    _onAdClicked = onAdClicked;
    _onAdShowed = onAdShowed;
    _onAdSwipe = onAdSwipe;

    LogUtils.log(
      'Loading ad ($listenerId) slotId=$slotId',
      tag: 'PangleNativeAd',
    );

    try {
      final result = await _channel.invokeMethod<bool>('loadNativeAd', {
        'listenerId': listenerId,
        'slotId': slotId,
        'style': _style.toMap(),
      });
      return result ?? false;
    } catch (e) {
      _isLoading = false;
      LogUtils.log('Load error ($listenerId): $e', tag: 'PangleNativeAd');
      onAdLoadFailed?.call(PangleAdError(code: -1, message: e.toString()));
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
            gestureRecognizers: _tapGestureRecognizers,
            hitTestBehavior: PlatformViewHitTestBehavior.translucent,
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
      pangleLog('[PangleNativeAd] Dispose error ($listenerId): $e');
    }
    _isLoaded = false;
    _isLoading = false;
    _onAdLoaded = null;
    _onAdLoadFailed = null;
    _onAdClicked = null;
    _onAdShowed = null;
    _onAdSwipe = null;
    _instances.remove(listenerId);
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;

  // ═══════════════════════════════════════════════════════════════════════
  // ── Legacy static API (backwards compatibility for single-instance) ───
  // ═══════════════════════════════════════════════════════════════════════

  static PangleNativeAd? _defaultInstance;

  static PangleNativeAd _ensureDefault() {
    return _defaultInstance ??= PangleNativeAd.create();
  }

  /// Legacy: load with the default (shared) instance.
  static Future<bool> load(
    String slotId, {
    NativeAdStyle? style,
    Function()? onAdLoaded,
    Function(PangleAdError error)? onAdLoadFailed,
    Function()? onAdClicked,
    Function()? onAdShowed,
    ValueChanged<int>? onAdSwipe,
  }) {
    return _ensureDefault().loadAd(
      slotId,
      style: style,
      onAdLoaded: onAdLoaded,
      onAdLoadFailed: onAdLoadFailed,
      onAdClicked: onAdClicked,
      onAdShowed: onAdShowed,
      onAdSwipe: onAdSwipe,
    );
  }

  /// Legacy: build the widget of the default instance.
  static Widget buildWidget() {
    final inst = _defaultInstance;
    if (inst == null) return const SizedBox.shrink();
    return inst.buildAdWidget();
  }

  /// Legacy: dispose the default instance.
  static Future<void> dispose() async {
    final inst = _defaultInstance;
    if (inst == null) return;
    await inst.disposeAd();
    _defaultInstance = null;
  }
}
