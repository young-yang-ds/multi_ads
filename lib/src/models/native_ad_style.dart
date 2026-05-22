import 'package:flutter/material.dart';

/// Vertical alignment for the text area in native ads.
/// Similar to Flutter's MainAxisAlignment.
enum NativeAdTextAlignment {
  /// Align to the top of the text area
  start,

  /// Center vertically in the text area
  center,

  /// Align to the bottom of the text area
  end,

  /// Equal spacing between title and body
  spaceBetween,

  /// Equal spacing around title and body
  spaceAround,

  /// Equal spacing including edges
  spaceEvenly,
}

/// Layout mode for native ads.
enum NativeAdLayoutMode {
  /// Default: icon on the left, title/body/CTA on the right.
  horizontal,

  /// Full-width main image on top, icon+title row below,
  /// full-width CTA at the bottom (suitable for full-screen native ads).
  vertical,
}

/// Scale mode for the main image in vertical layout.
enum NativeAdImageScaleMode {
  /// Fill the area by cropping (Android CENTER_CROP / iOS scaleAspectFill).
  cover,

  /// Fit inside without cropping, may letterbox (Android FIT_CENTER / iOS scaleAspectFit).
  contain,

  /// Stretch to fill, may distort (Android FIT_XY / iOS scaleToFill).
  fill,
}

/// Source selection for the main image in vertical layout.
enum NativeAdMainImageSource {
  /// Auto: prefer media image (large), fall back to icon.
  auto,

  /// Use the media image only (Google only; ignored on Pangle/Vungle).
  media,

  /// Use the icon image only.
  icon,
}

/// Vertical content alignment inside the ad container (vertical layout only).
enum NativeAdVerticalContentAlignment {
  /// Align content to the top of the container (default).
  top,

  /// Center content vertically inside the container.
  center,

  /// Align content to the bottom of the container.
  bottom,
}

/// Style configuration for native ads in factory mode.
///
/// All style properties are passed to the native side via `customOptions`
/// and applied dynamically by the built-in NativeAdFactory.
///
/// Usage:
/// ```dart
/// GoogleNativeAd.load(
///   'ad-unit-id',
///   style: NativeAdStyle(
///     height: 80,
///     imageWidth: 120,
///     titleFontSize: 14,
///     titleColor: Color(0xFF202124),
///     bodyFontSize: 10,
///     bodyColor: Color(0xFF999999),
///     backgroundColor: Colors.white,
///     cornerRadius: 10,
///   ),
///   onAdLoadedRefresh: () => setState(() {}),
/// );
/// ```
class NativeAdStyle {
  /// Height of the ad container (default: 80)
  final double height;

  /// Width of the left image (default: 120)
  final double imageWidth;

  /// Height of the left image, defaults to [height] if not set
  final double? imageHeight;

  /// Corner radius of the image (default: 0, no rounding)
  final double imageCornerRadius;

  /// Title font size in sp/pt (default: 14)
  final double titleFontSize;

  /// Title text color (default: #202124)
  final Color titleColor;

  /// Whether title text is bold (default: true)
  final bool titleBold;

  /// Title max lines (default: 2)
  final int titleMaxLines;

  /// Custom font family name for title (default: null = system font)
  final String? titleFontFamily;

  /// Body/subtitle font size in sp/pt (default: 10)
  final double bodyFontSize;

  /// Body/subtitle text color (default: #999999)
  final Color bodyColor;

  /// Whether body text is bold (default: false)
  final bool bodyBold;

  /// Custom font family name for body (default: null = system font)
  final String? bodyFontFamily;

  /// Background color of the ad (default: white)
  final Color backgroundColor;

  /// Corner radius (default: 10)
  final double cornerRadius;

  /// Horizontal padding for the text area (default: 12)
  final double textPaddingHorizontal;

  /// Vertical padding for the text area (default: 8)
  final double textPaddingVertical;

  /// Vertical alignment of the text area (default: center)
  final NativeAdTextAlignment textAlignment;

  /// Whether to show star rating if available (default: true)
  final bool showStarRating;

  /// Size of star icons in dp/pt (default: 12)
  final double starSize;

  /// Color of filled stars (default: amber)
  final Color starActiveColor;

  /// Color of empty stars (default: #CCCCCC)
  final Color starInactiveColor;

  /// Whether to show call-to-action button if available (default: true)
  final bool showCallToAction;

  /// CTA button font size (default: 12)
  final double ctaFontSize;

  /// CTA button text color (default: white)
  final Color ctaTextColor;

  /// CTA button background color (default: #4285F4 Google blue)
  final Color ctaBackgroundColor;

  /// CTA button corner radius (default: 4)
  final double ctaCornerRadius;

  /// Whether CTA text is bold (default: true)
  final bool ctaBold;

  /// CTA button horizontal padding (default: 8)
  final double ctaPaddingHorizontal;

  /// External margin around the ad widget (default: EdgeInsets.zero)
  /// This is applied at the Flutter widget level, not passed to native side.
  final EdgeInsetsGeometry margin;

  /// Layout mode for the native ad.
  /// - [NativeAdLayoutMode.horizontal] (default): icon on the left, title/body/CTA on the right.
  /// - [NativeAdLayoutMode.vertical]: full-width main image on top, icon+title row below,
  ///   full-width CTA at the bottom (suitable for full-screen native ads).
  final NativeAdLayoutMode layoutMode;

  // ─── Vertical-mode main image controls ───────────────────────────────

  /// (vertical only) Height of the top main image. Defaults to [imageHeight] when null.
  final double? mainImageHeight;

  /// (vertical only) Scale mode of the top main image. Default: [NativeAdImageScaleMode.cover].
  final NativeAdImageScaleMode mainImageScaleMode;

  /// (vertical only) Corner radius of the top main image. Default: 0.
  final double mainImageCornerRadius;

  /// (vertical only) Background color of the main image area
  /// (visible as letterbox bars when scaleMode = contain). Default: transparent.
  final Color mainImageBackgroundColor;

  /// (vertical only) Source of the top main image. Default: [NativeAdMainImageSource.auto].
  final NativeAdMainImageSource mainImageSource;

  /// (vertical only) Outer padding around the main image
  /// (gap between the image and the ad container edges). Default: [EdgeInsets.zero].
  final EdgeInsets mainImagePadding;

  /// (vertical only) Where to align the content block (image + title row + CTA)
  /// inside the ad container along the vertical axis.
  /// Default: [NativeAdVerticalContentAlignment.top].
  final NativeAdVerticalContentAlignment verticalContentAlignment;

  const NativeAdStyle({
    this.height = 80,
    this.imageWidth = 120,
    this.imageHeight,
    this.imageCornerRadius = 0,
    this.titleFontSize = 14,
    this.titleColor = const Color(0xFF202124),
    this.titleBold = true,
    this.titleMaxLines = 2,
    this.titleFontFamily,
    this.bodyFontSize = 10,
    this.bodyColor = const Color(0xFF999999),
    this.bodyBold = false,
    this.bodyFontFamily,
    this.backgroundColor = const Color(0xFFFFFFFF),
    this.cornerRadius = 10,
    this.textPaddingHorizontal = 12,
    this.textPaddingVertical = 8,
    this.textAlignment = NativeAdTextAlignment.center,
    this.showStarRating = true,
    this.starSize = 12,
    this.starActiveColor = const Color(0xFFFFC107),
    this.starInactiveColor = const Color(0xFFCCCCCC),
    this.showCallToAction = true,
    this.ctaFontSize = 12,
    this.ctaTextColor = const Color(0xFFFFFFFF),
    this.ctaBackgroundColor = const Color(0xFF4285F4),
    this.ctaCornerRadius = 4,
    this.ctaBold = true,
    this.ctaPaddingHorizontal = 8,
    this.margin = EdgeInsets.zero,
    this.layoutMode = NativeAdLayoutMode.horizontal,
    this.mainImageHeight,
    this.mainImageScaleMode = NativeAdImageScaleMode.cover,
    this.mainImageCornerRadius = 0,
    this.mainImageBackgroundColor = const Color(0x00000000),
    this.mainImageSource = NativeAdMainImageSource.auto,
    this.mainImagePadding = EdgeInsets.zero,
    this.verticalContentAlignment = NativeAdVerticalContentAlignment.top,
  });

  /// Convert to a Map for passing as customOptions to native side
  Map<String, Object> toMap() {
    return {
      'height': height,
      'imageWidth': imageWidth,
      'imageHeight': imageHeight ?? height,
      'imageCornerRadius': imageCornerRadius,
      'titleFontSize': titleFontSize,
      'titleColor': _colorToHex(titleColor),
      'titleBold': titleBold,
      'titleMaxLines': titleMaxLines,
      if (titleFontFamily != null) 'titleFontFamily': titleFontFamily!,
      'bodyFontSize': bodyFontSize,
      'bodyColor': _colorToHex(bodyColor),
      'bodyBold': bodyBold,
      if (bodyFontFamily != null) 'bodyFontFamily': bodyFontFamily!,
      'backgroundColor': _colorToHex(backgroundColor),
      'cornerRadius': cornerRadius,
      'textPaddingHorizontal': textPaddingHorizontal,
      'textPaddingVertical': textPaddingVertical,
      'textAlignment': textAlignment.name,
      'showStarRating': showStarRating,
      'starSize': starSize,
      'starActiveColor': _colorToHex(starActiveColor),
      'starInactiveColor': _colorToHex(starInactiveColor),
      'showCallToAction': showCallToAction,
      'ctaFontSize': ctaFontSize,
      'ctaTextColor': _colorToHex(ctaTextColor),
      'ctaBackgroundColor': _colorToHex(ctaBackgroundColor),
      'ctaCornerRadius': ctaCornerRadius,
      'ctaBold': ctaBold,
      'ctaPaddingHorizontal': ctaPaddingHorizontal,
      'layoutMode': layoutMode.name,
      if (mainImageHeight != null) 'mainImageHeight': mainImageHeight!,
      'mainImageScaleMode': mainImageScaleMode.name,
      'mainImageCornerRadius': mainImageCornerRadius,
      'mainImageBackgroundColor': _colorToHex(mainImageBackgroundColor),
      'mainImageSource': mainImageSource.name,
      'mainImagePaddingLeft': mainImagePadding.left,
      'mainImagePaddingTop': mainImagePadding.top,
      'mainImagePaddingRight': mainImagePadding.right,
      'mainImagePaddingBottom': mainImagePadding.bottom,
      'verticalContentAlignment': verticalContentAlignment.name,
    };
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }
}
