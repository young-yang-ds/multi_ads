import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'models/ad_error.dart';
import 'pangle_method_channel.dart';

enum BannerAdSize {
  banner320x50,
  banner300x250,
  banner728x90,
  anchoredAdaptive,
}

class PangleBannerAdWidget extends StatefulWidget {
  final String slotId;
  final BannerAdSize adSize;
  final Function()? onAdLoaded;
  final Function(PangleAdError error)? onAdLoadFailed;
  final Function()? onAdClicked;

  const PangleBannerAdWidget({
    Key? key,
    required this.slotId,
    this.adSize = BannerAdSize.banner320x50,
    this.onAdLoaded,
    this.onAdLoadFailed,
    this.onAdClicked,
  }) : super(key: key);

  @override
  State<PangleBannerAdWidget> createState() => _PangleBannerAdWidgetState();
}

class _BannerChannelHandler {
  static final _BannerChannelHandler _instance =
      _BannerChannelHandler._internal();

  factory _BannerChannelHandler() => _instance;

  _BannerChannelHandler._internal();

  static const MethodChannel _channel = MethodChannel('multi_ads/pangle_global');
  final Map<String, _PangleBannerAdWidgetState> _listeners = {};
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) {
      pangleLog('[Flutter Banner] Handler already initialized');
      return;
    }
    _isInitialized = true;
    pangleLog('[Flutter Banner] Initializing global channel handler');

    _channel.setMethodCallHandler((call) async {
      pangleLog('[Flutter Banner] Received method call: ${call.method}');

      pangleLog('[Flutter Banner] Active listeners: ${_listeners.length}');

      // Notify all registered listeners
      for (var listener in _listeners.values) {
        switch (call.method) {
          case 'onBannerAdLoaded':
            pangleLog('[Flutter Banner] Ad loaded successfully');
            listener.onAdLoadedInternal();
            break;
          case 'onBannerAdLoadFailed':
            final error = PangleAdError.fromJson(
              Map<String, dynamic>.from(call.arguments as Map),
            );
            pangleLog(
                '[Flutter Banner] Ad load failed: ${error.code} - ${error.message}');
            listener.widget.onAdLoadFailed?.call(error);
            break;
          case 'onBannerAdClicked':
            pangleLog('[Flutter Banner] Ad clicked - calling callback');
            if (listener.widget.onAdClicked != null) {
              pangleLog(
                  '[Flutter Banner] onAdClicked callback exists, calling it');
              listener.widget.onAdClicked?.call();
              pangleLog('[Flutter Banner] onAdClicked callback called');
            } else {
              pangleLog('[Flutter Banner] onAdClicked callback is null');
            }
            break;
          default:
            pangleLog('[Flutter Banner] Unknown method: ${call.method}');
        }
      }
    });
    pangleLog('[Flutter Banner] Channel handler setup complete');
  }

  void registerListener(String id, _PangleBannerAdWidgetState listener) {
    _listeners[id] = listener;
    pangleLog(
        '[Flutter Banner] Registered listener: $id, total: ${_listeners.length}');
  }

  void unregisterListener(String id) {
    _listeners.remove(id);
    pangleLog(
        '[Flutter Banner] Unregistered listener: $id, remaining: ${_listeners.length}');
  }
}

class _PangleBannerAdWidgetState extends State<PangleBannerAdWidget> {
  late final String _listenerId;
  final _channelHandler = _BannerChannelHandler();
  bool _isAdLoaded = false;
  Widget? _platformView;

  void onAdLoadedInternal() {
    if (mounted) {
      setState(() {
        _isAdLoaded = true;
      });
    }
    widget.onAdLoaded?.call();
  }

  @override
  void initState() {
    super.initState();
    _listenerId = '${widget.slotId}_${DateTime.now().millisecondsSinceEpoch}';
    _channelHandler.initialize();
    _channelHandler.registerListener(_listenerId, this);
  }

  @override
  void dispose() {
    _channelHandler.unregisterListener(_listenerId);
    super.dispose();
  }

  Size _getAdSize() {
    switch (widget.adSize) {
      case BannerAdSize.banner320x50:
        return const Size(320, 50);
      case BannerAdSize.banner300x250:
        return const Size(300, 250);
      case BannerAdSize.banner728x90:
        return const Size(728, 90);
      case BannerAdSize.anchoredAdaptive:
        final screenWidth = MediaQuery.of(context).size.width;
        return Size(screenWidth, 90);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _getAdSize();
    pangleLog(
        '[Flutter Banner] Building banner widget - slotId: ${widget.slotId}, size: ${size.width}x${size.height}, loaded: $_isAdLoaded');

    _platformView ??= _buildPlatformView();

    return Visibility(
      visible: _isAdLoaded,
      maintainState: true,
      maintainSize: false,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: _platformView,
      ),
    );
  }

  Widget _buildPlatformView() {
    final Map<String, dynamic> creationParams = {
      'slotId': widget.slotId,
      'adSize': widget.adSize.index,
    };
    pangleLog(
        '[Flutter Banner] Creating platform view with params: $creationParams');
    pangleLog('[Flutter Banner] Platform: $defaultTargetPlatform');

    if (defaultTargetPlatform == TargetPlatform.android) {
      return PlatformViewLink(
        viewType: 'multi_ads/pangle_global/banner',
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
            viewType: 'multi_ads/pangle_global/banner',
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
      return UiKitView(
        viewType: 'multi_ads/pangle_global/banner',
        layoutDirection: TextDirection.ltr,
        creationParams: creationParams,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Text('Platform not supported'),
      ),
    );
  }
}
