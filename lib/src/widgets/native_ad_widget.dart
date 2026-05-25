import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart' hide AdError;
import 'package:google_mobile_ads/src/ad_instance_manager.dart'
    as google_mobile_ads;

import '../../multi_ads.dart';
import '../utils/log_utils.dart';

final Set<Factory<OneSequenceGestureRecognizer>> _tapGestureRecognizers =
    <Factory<OneSequenceGestureRecognizer>>{
      Factory<OneSequenceGestureRecognizer>(() => TapGestureRecognizer()),
    };

/// A widget that displays native ads. Supports multiple simultaneous instances
/// for all platforms (Google, Pangle, Vungle). Each widget instance manages
/// its own ad object, so listing many ads in a scroll view works correctly.
///
/// Usage:
/// ```dart
/// NativeAdWidget(
///   adUnitId: 'your-ad-unit-id',
///   adPlatform: AdPlatform.google,
///   style: NativeAdStyle(height: 80, cornerRadius: 10),
///   placeholder: SizedBox(height: 80),
///   onAdLoaded: () => debugPrint('Ad loaded'),
///   onAdFailed: (error) => debugPrint('Ad failed: $error'),
/// )
/// ```
class NativeAdWidget extends StatefulWidget {
  /// The ad unit ID / slot ID / placement ID
  final String adUnitId;

  /// The ad platform to use
  final AdPlatform adPlatform;

  /// Custom style configuration (factory mode).
  /// When provided, uses native NativeAdFactory for rendering.
  final NativeAdStyle? style;

  /// Google only: Template type (ignored when [style] is provided)
  final TemplateType templateType;

  /// Google only: Custom template style (ignored when [style] is provided)
  final NativeTemplateStyle? nativeTemplateStyle;

  /// Widget to show while ad is loading.
  /// Defaults to [SizedBox.shrink] if not provided.
  final Widget? placeholder;

  /// Called when the ad is successfully loaded
  final VoidCallback? onAdLoaded;

  /// Called when the ad fails to load
  final Function(AdError error)? onAdFailed;

  /// Called when the ad is clicked
  final VoidCallback? onAdClicked;

  /// Called when a vertical swipe is detected inside a native platform view.
  /// Direction is `1` for next page and `-1` for previous page.
  final ValueChanged<int>? onVerticalSwipe;

  /// Whether to keep the widget alive when scrolled off-screen in a list.
  /// Defaults to `true` to avoid expensive ad reloads.
  /// Set to `false` if you want the ad to be disposed when not visible.
  final bool keepAlive;

  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    required this.adPlatform,
    this.style,
    this.templateType = TemplateType.medium,
    this.nativeTemplateStyle,
    this.placeholder,
    this.onAdLoaded,
    this.onAdFailed,
    this.onAdClicked,
    this.onVerticalSwipe,
    this.keepAlive = true,
  });

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget>
    with AutomaticKeepAliveClientMixin {
  // ── Instance state ─────────────────────────────────────────────────────

  bool _isAdLoaded = false;

  /// Google: each instance holds its own NativeAd object (multi-instance).
  NativeAd? _googleNativeAd;

  /// Pangle: each instance holds its own PangleNativeAd (multi-instance).
  PangleNativeAd? _pangleNativeAd;

  /// Vungle: each instance holds its own VungleNativeAd (multi-instance).
  VungleNativeAd? _vungleNativeAd;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  bool get _isGoogle => widget.adPlatform == AdPlatform.google;
  bool get _isPangle => widget.adPlatform == AdPlatform.pangleGlobal;
  bool get _isVungle => widget.adPlatform == AdPlatform.vungle;

  // ── Lifecycle ──────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    if (_isGoogle) {
      _loadGoogleAd();
    } else if (_isPangle) {
      _loadPangleAd();
    } else if (_isVungle) {
      _loadVungleAd();
    }
  }

  @override
  void dispose() {
    if (_isGoogle) {
      _disposeGoogleAd();
    } else if (_isPangle) {
      _disposePangleAd();
    } else if (_isVungle) {
      _disposeVungleAd();
    }
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Google: Multi-instance support ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  void _loadGoogleAd() {
    final style = widget.style;
    final useFactory = style != null;

    LogUtils.log(
      'Loading Google native ad (instance: ${hashCode.toRadixString(16)})',
      tag: 'NativeAdWidget',
    );

    if (useFactory) {
      LogUtils.log('Native ad loading (custom style)', tag: 'google ads');
      _googleNativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: 'multiAdsNativeFactory',
        customOptions: style.toMap(),
        request: const AdRequest(),
        listener: _googleAdListener,
      )..load();
    } else {
      LogUtils.log(
        'Native ad loading (template: ${widget.templateType})',
        tag: 'google ads',
      );
      _googleNativeAd = NativeAd(
        adUnitId: widget.adUnitId,
        request: const AdRequest(),
        nativeTemplateStyle:
            widget.nativeTemplateStyle ??
            NativeTemplateStyle(templateType: widget.templateType),
        listener: _googleAdListener,
      )..load();
    }
  }

  NativeAdListener get _googleAdListener => NativeAdListener(
    onAdLoaded: (ad) {
      if (mounted) {
        LogUtils.log('Native ad loaded', tag: 'google ads');
        setState(() => _isAdLoaded = true);
        widget.onAdLoaded?.call();
      }
    },
    onAdFailedToLoad: (ad, error) {
      ad.dispose();
      _googleNativeAd = null;
      LogUtils.log(
        'Native ad load failed: ${error.code} - ${error.message}',
        tag: 'google ads',
      );
      if (mounted) {
        widget.onAdFailed?.call(
          AdError(code: error.code, message: error.message, platform: 'google'),
        );
      }
    },
    onAdClicked: (ad) {
      LogUtils.log('Native ad clicked', tag: 'google ads');
      widget.onAdClicked?.call();
    },
    onAdImpression: (ad) {
      LogUtils.log('Native ad impression', tag: 'google ads');
    },
  );

  void _disposeGoogleAd() {
    _googleNativeAd?.dispose();
    _googleNativeAd = null;
    _isAdLoaded = false;
    LogUtils.log(
      'Disposed Google native ad (instance: ${hashCode.toRadixString(16)})',
      tag: 'NativeAdWidget',
    );
  }

  Widget _buildGoogleAdWidget() {
    if (_googleNativeAd == null || !_isAdLoaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }

    final adWidget = _GestureAwareGoogleAdWidget(
      key: ObjectKey(_googleNativeAd!),
      ad: _googleNativeAd!,
    );
    final style = widget.style;

    if (style != null) {
      return Padding(
        padding: style.margin,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(style.cornerRadius),
          child: SizedBox(
            width: double.infinity,
            height: style.height,
            child: adWidget,
          ),
        ),
      );
    }

    final constraints = widget.templateType == TemplateType.small
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
      child: ConstrainedBox(constraints: constraints, child: adWidget),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Pangle: Multi-instance support ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  void _loadPangleAd() {
    _pangleNativeAd = PangleNativeAd.create();
    LogUtils.log(
      'Loading Pangle native ad (listenerId: ${_pangleNativeAd!.listenerId})',
      tag: 'NativeAdWidget',
    );
    _pangleNativeAd!.loadAd(
      widget.adUnitId,
      style: widget.style,
      onAdLoaded: () {
        if (mounted) {
          setState(() => _isAdLoaded = true);
          widget.onAdLoaded?.call();
        }
      },
      onAdLoadFailed: (error) {
        if (mounted) {
          LogUtils.log(
            'Pangle native ad load failed: ${error.code} - ${error.message}',
            tag: 'NativeAdWidget',
          );
          widget.onAdFailed?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'pangleGlobal',
            ),
          );
        }
      },
      onAdClicked: () => widget.onAdClicked?.call(),
      onAdSwipe: widget.onVerticalSwipe,
    );
  }

  void _disposePangleAd() {
    final id = _pangleNativeAd?.listenerId;
    _pangleNativeAd?.disposeAd();
    _pangleNativeAd = null;
    _isAdLoaded = false;
    LogUtils.log(
      'Disposed Pangle native ad (listenerId: $id)',
      tag: 'NativeAdWidget',
    );
  }

  Widget _buildPangleAdWidget() {
    if (_pangleNativeAd == null || !_isAdLoaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return _pangleNativeAd!.buildAdWidget();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Vungle: Multi-instance support ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  void _loadVungleAd() {
    _vungleNativeAd = VungleNativeAd.create();
    LogUtils.log(
      'Loading Vungle native ad (listenerId: ${_vungleNativeAd!.listenerId})',
      tag: 'NativeAdWidget',
    );
    _vungleNativeAd!.loadAd(
      widget.adUnitId,
      style: widget.style,
      onAdLoaded: () {
        if (mounted) {
          setState(() => _isAdLoaded = true);
          widget.onAdLoaded?.call();
        }
      },
      onAdLoadFailed: (error) {
        if (mounted) {
          LogUtils.log(
            'Vungle native ad load failed: ${error.code} - ${error.message}',
            tag: 'NativeAdWidget',
          );
          widget.onAdFailed?.call(
            AdError(
              code: error.code,
              message: error.message,
              platform: 'vungle',
            ),
          );
        }
      },
      onAdClicked: () => widget.onAdClicked?.call(),
      onAdSwipe: widget.onVerticalSwipe,
    );
  }

  void _disposeVungleAd() {
    final id = _vungleNativeAd?.listenerId;
    _vungleNativeAd?.disposeAd();
    _vungleNativeAd = null;
    _isAdLoaded = false;
    LogUtils.log(
      'Disposed Vungle native ad (listenerId: $id)',
      tag: 'NativeAdWidget',
    );
  }

  Widget _buildVungleAdWidget() {
    if (_vungleNativeAd == null || !_isAdLoaded) {
      return widget.placeholder ?? const SizedBox.shrink();
    }
    return _vungleNativeAd!.buildAdWidget();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── Build ──────────────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin

    if (_isGoogle) {
      if (_isAdLoaded) {
        return _buildGoogleAdWidget();
      }
      return widget.placeholder ?? const SizedBox.shrink();
    }

    if (_isPangle) {
      if (_isAdLoaded) {
        return _buildPangleAdWidget();
      }
      return widget.placeholder ?? const SizedBox.shrink();
    }

    if (_isVungle) {
      if (_isAdLoaded) {
        return _buildVungleAdWidget();
      }
      return widget.placeholder ?? const SizedBox.shrink();
    }

    return widget.placeholder ?? const SizedBox.shrink();
  }
}

class _GestureAwareGoogleAdWidget extends StatefulWidget {
  final AdWithView ad;

  const _GestureAwareGoogleAdWidget({super.key, required this.ad});

  @override
  State<_GestureAwareGoogleAdWidget> createState() =>
      _GestureAwareGoogleAdWidgetState();
}

class _GestureAwareGoogleAdWidgetState
    extends State<_GestureAwareGoogleAdWidget> {
  bool _adIdAlreadyMounted = false;
  bool _adLoadNotCalled = false;

  @override
  void initState() {
    super.initState();
    final adId = google_mobile_ads.instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      if (google_mobile_ads.instanceManager.isWidgetAdIdMounted(adId)) {
        _adIdAlreadyMounted = true;
      }
      google_mobile_ads.instanceManager.mountWidgetAdId(adId);
    } else {
      _adLoadNotCalled = true;
    }
  }

  @override
  void dispose() {
    final adId = google_mobile_ads.instanceManager.adIdFor(widget.ad);
    if (adId != null) {
      google_mobile_ads.instanceManager.unmountWidgetAdId(adId);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_adIdAlreadyMounted) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('This AdWidget is already in the Widget tree'),
        ErrorHint(
          'If you placed this AdWidget in a list, make sure you create a new '
          'instance in the builder function with a unique ad object.',
        ),
        ErrorHint(
          'Make sure you are not using the same ad object in more than one AdWidget.',
        ),
      ]);
    }
    if (_adLoadNotCalled) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary(
          'AdWidget requires Ad.load to be called before AdWidget is inserted into the tree',
        ),
        ErrorHint(
          'Parameter ad is not loaded. Call Ad.load before AdWidget is inserted into the tree.',
        ),
      ]);
    }

    final adId = google_mobile_ads.instanceManager.adIdFor(widget.ad);
    final viewType =
        '${google_mobile_ads.instanceManager.channel.name}/ad_widget';

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            gestureRecognizers: _tapGestureRecognizers,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: adId,
              creationParamsCodec: const StandardMessageCodec(),
            )
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    }

    return UiKitView(
      viewType: viewType,
      creationParams: adId,
      creationParamsCodec: const StandardMessageCodec(),
      gestureRecognizers: _tapGestureRecognizers,
      hitTestBehavior: PlatformViewHitTestBehavior.opaque,
    );
  }
}
