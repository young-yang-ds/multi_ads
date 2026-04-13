import Foundation
import UIKit
import GoogleMobileAds

/// Builds a styled NativeAdView from a NativeAd and customOptions dictionary.
///
/// This class reads styling parameters from the customOptions map passed by
/// the Dart side via NativeAdStyle.toMap(), so all styling is controlled from Dart.
///
/// Usage in your app's NativeAdFactory:
/// ```swift
/// class NativeAdFactoryImpl: FLTNativeAdFactory {
///     func createNativeAd(_ nativeAd: NativeAd,
///                         customOptions: [AnyHashable: Any]?) -> NativeAdView? {
///         return NativeAdViewBuilder.build(nativeAd: nativeAd, customOptions: customOptions)
///     }
/// }
/// ```
public class NativeAdViewBuilder: NSObject {

    public static func build(nativeAd: NativeAd, customOptions: [AnyHashable: Any]?) -> NativeAdView {
        let options = customOptions ?? [:]

        // Read style options from Dart NativeAdStyle
        let height = (options["height"] as? Double) ?? 80.0
        let imageWidth = (options["imageWidth"] as? Double) ?? 120.0
        let imageHeight = (options["imageHeight"] as? Double) ?? height
        let titleFontSize = (options["titleFontSize"] as? Double) ?? 14.0
        let titleColorStr = (options["titleColor"] as? String) ?? "#FF202124"
        let titleBold = (options["titleBold"] as? Bool) ?? true
        let titleMaxLines = (options["titleMaxLines"] as? Int) ?? 2
        let titleFontFamily = options["titleFontFamily"] as? String
        let bodyFontSize = (options["bodyFontSize"] as? Double) ?? 10.0
        let bodyColorStr = (options["bodyColor"] as? String) ?? "#FF999999"
        let bodyBold = (options["bodyBold"] as? Bool) ?? false
        let bodyFontFamily = options["bodyFontFamily"] as? String
        let bgColorStr = (options["backgroundColor"] as? String) ?? "#FFFFFFFF"
        let cornerRadius = (options["cornerRadius"] as? Double) ?? 10.0
        let textPadH = (options["textPaddingHorizontal"] as? Double) ?? 12.0
        let textPadV = (options["textPaddingVertical"] as? Double) ?? 8.0
        let textAlignment = (options["textAlignment"] as? String) ?? "center"
        let showStarRating = (options["showStarRating"] as? Bool) ?? true
        let starSize = (options["starSize"] as? Double) ?? 12.0
        let starActiveColorStr = (options["starActiveColor"] as? String) ?? "#FFFFC107"
        let starInactiveColorStr = (options["starInactiveColor"] as? String) ?? "#FFCCCCCC"
        let showCallToAction = (options["showCallToAction"] as? Bool) ?? true
        let ctaFontSize = (options["ctaFontSize"] as? Double) ?? 12.0
        let ctaTextColorStr = (options["ctaTextColor"] as? String) ?? "#FFFFFFFF"
        let ctaBgColorStr = (options["ctaBackgroundColor"] as? String) ?? "#FF4285F4"
        let ctaCornerRadiusVal = (options["ctaCornerRadius"] as? Double) ?? 4.0
        let ctaBold = (options["ctaBold"] as? Bool) ?? true

        let titleColor = parseColor(titleColorStr)
        let bodyColor = parseColor(bodyColorStr)
        let bgColor = parseColor(bgColorStr)

        // NativeAdView
        let adView = NativeAdView()
        adView.backgroundColor = bgColor
        adView.clipsToBounds = true
        adView.layer.cornerRadius = CGFloat(cornerRadius)

        // Thumbnail
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(iconImageView)
        adView.iconView = iconImageView

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.font = makeFont(size: titleFontSize, bold: titleBold, family: titleFontFamily)
        headlineLabel.textColor = titleColor
        headlineLabel.numberOfLines = titleMaxLines
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // Body
        let bodyLabel = UILabel()
        bodyLabel.font = makeFont(size: bodyFontSize, bold: bodyBold, family: bodyFontFamily)
        bodyLabel.textColor = bodyColor
        bodyLabel.numberOfLines = 1
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(bodyLabel)
        adView.bodyView = bodyLabel

        // Bottom row: star rating + CTA button
        let starRating = nativeAd.starRating
        let callToAction = nativeAd.callToAction
        let hasStarRating = showStarRating && starRating != nil
        let hasCta = showCallToAction && callToAction != nil

        var starsLabel: UILabel? = nil
        var ctaLabel: UILabel? = nil

        if hasStarRating {
            let starActiveColor = parseColor(starActiveColorStr)
            let starInactiveColor = parseColor(starInactiveColorStr)
            let rating = starRating!.intValue
            let label = UILabel()
            let starText = NSMutableAttributedString()
            for i in 1...5 {
                let char = i <= rating ? "★" : "☆"
                let color = i <= rating ? starActiveColor : starInactiveColor
                starText.append(NSAttributedString(string: char, attributes: [
                    .foregroundColor: color,
                    .font: UIFont.systemFont(ofSize: CGFloat(starSize))
                ]))
            }
            label.attributedText = starText
            label.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview(label)
            adView.starRatingView = label
            starsLabel = label
        }

        if hasCta {
            let ctaTextColor = parseColor(ctaTextColorStr)
            let ctaBgColor = parseColor(ctaBgColorStr)
            let label = UILabel()
            label.text = callToAction
            label.font = makeFont(size: ctaFontSize, bold: ctaBold, family: nil)
            label.textColor = ctaTextColor
            label.textAlignment = .center
            label.backgroundColor = ctaBgColor
            label.layer.cornerRadius = CGFloat(ctaCornerRadiusVal)
            label.clipsToBounds = true
            // Padding via content insets workaround
            label.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview(label)
            adView.callToActionView = label
            ctaLabel = label
        }

        // Text wrapper for vertical alignment
        let textWrapper = UIView()
        textWrapper.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(textWrapper)
        textWrapper.addSubview(headlineLabel)
        textWrapper.addSubview(bodyLabel)
        if let stars = starsLabel { textWrapper.addSubview(stars) }
        if let cta = ctaLabel { textWrapper.addSubview(cta) }

        // Determine the bottom-most element in text wrapper
        // Layout: headline -> body -> bottomRow (stars + cta)
        let hasBottomRow = hasStarRating || hasCta
        let bottomAnchorView: UIView = hasBottomRow
            ? (hasCta ? ctaLabel! : starsLabel!)
            : bodyLabel

        // Layout constraints
        var constraints: [NSLayoutConstraint] = [
            iconImageView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
            iconImageView.topAnchor.constraint(equalTo: adView.topAnchor),
            iconImageView.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: CGFloat(imageWidth)),

            textWrapper.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: CGFloat(textPadH)),
            textWrapper.trailingAnchor.constraint(equalTo: adView.trailingAnchor, constant: -CGFloat(textPadH)),

            headlineLabel.leadingAnchor.constraint(equalTo: textWrapper.leadingAnchor),
            headlineLabel.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor),

            bodyLabel.leadingAnchor.constraint(equalTo: textWrapper.leadingAnchor),
            bodyLabel.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor),
        ]

        // Star rating & CTA constraints (horizontal row below body)
        if hasBottomRow {
            if let stars = starsLabel {
                constraints.append(stars.leadingAnchor.constraint(equalTo: textWrapper.leadingAnchor))
                constraints.append(stars.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4))
            }
            if let cta = ctaLabel {
                constraints.append(cta.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor))
                constraints.append(cta.heightAnchor.constraint(equalToConstant: CGFloat(ctaFontSize + 10)))
                constraints.append(cta.widthAnchor.constraint(greaterThanOrEqualToConstant: 50))
                if hasStarRating {
                    constraints.append(cta.centerYAnchor.constraint(equalTo: starsLabel!.centerYAnchor))
                } else {
                    constraints.append(cta.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4))
                }
            }
        }

        switch textAlignment {
        case "start":
            constraints += [
                textWrapper.topAnchor.constraint(equalTo: adView.topAnchor, constant: CGFloat(textPadV)),
                textWrapper.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor),
                headlineLabel.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
                bottomAnchorView.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
            ]
        case "end":
            constraints += [
                textWrapper.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -CGFloat(textPadV)),
                textWrapper.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor),
                headlineLabel.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
                bottomAnchorView.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
            ]
        case "spaceBetween":
            constraints += [
                textWrapper.topAnchor.constraint(equalTo: adView.topAnchor, constant: CGFloat(textPadV)),
                textWrapper.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -CGFloat(textPadV)),
                headlineLabel.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                bottomAnchorView.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
            ]
        case "spaceAround":
            let topGuide = UILayoutGuide()
            let midGuide = UILayoutGuide()
            let bottomGuide = UILayoutGuide()
            adView.addLayoutGuide(topGuide)
            adView.addLayoutGuide(midGuide)
            adView.addLayoutGuide(bottomGuide)
            constraints += [
                textWrapper.topAnchor.constraint(equalTo: adView.topAnchor, constant: CGFloat(textPadV)),
                textWrapper.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -CGFloat(textPadV)),
                topGuide.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                topGuide.bottomAnchor.constraint(equalTo: headlineLabel.topAnchor),
                midGuide.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor),
                midGuide.bottomAnchor.constraint(equalTo: bodyLabel.topAnchor),
                bottomGuide.topAnchor.constraint(equalTo: bottomAnchorView.bottomAnchor),
                bottomGuide.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
                midGuide.heightAnchor.constraint(equalTo: topGuide.heightAnchor, multiplier: 2),
                bottomGuide.heightAnchor.constraint(equalTo: topGuide.heightAnchor),
            ]
        case "spaceEvenly":
            let topGuide = UILayoutGuide()
            let midGuide = UILayoutGuide()
            let bottomGuide = UILayoutGuide()
            adView.addLayoutGuide(topGuide)
            adView.addLayoutGuide(midGuide)
            adView.addLayoutGuide(bottomGuide)
            constraints += [
                textWrapper.topAnchor.constraint(equalTo: adView.topAnchor, constant: CGFloat(textPadV)),
                textWrapper.bottomAnchor.constraint(equalTo: adView.bottomAnchor, constant: -CGFloat(textPadV)),
                topGuide.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                topGuide.bottomAnchor.constraint(equalTo: headlineLabel.topAnchor),
                midGuide.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor),
                midGuide.bottomAnchor.constraint(equalTo: bodyLabel.topAnchor),
                bottomGuide.topAnchor.constraint(equalTo: bottomAnchorView.bottomAnchor),
                bottomGuide.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
                midGuide.heightAnchor.constraint(equalTo: topGuide.heightAnchor),
                bottomGuide.heightAnchor.constraint(equalTo: topGuide.heightAnchor),
            ]
        default: // center
            constraints += [
                textWrapper.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
                headlineLabel.topAnchor.constraint(equalTo: textWrapper.topAnchor),
                bodyLabel.topAnchor.constraint(equalTo: headlineLabel.bottomAnchor, constant: 4),
                bottomAnchorView.bottomAnchor.constraint(equalTo: textWrapper.bottomAnchor),
            ]
        }

        NSLayoutConstraint.activate(constraints)

        // Bind data
        (adView.headlineView as? UILabel)?.text = nativeAd.headline
        (adView.bodyView as? UILabel)?.text = nativeAd.body
        if let icon = nativeAd.icon?.image {
            (adView.iconView as? UIImageView)?.image = icon
        }

        adView.nativeAd = nativeAd
        return adView
    }

    private static func makeFont(size: Double, bold: Bool, family: String?) -> UIFont {
        let fontSize = CGFloat(size)
        if let family = family, let font = UIFont(name: family, size: fontSize) {
            if bold {
                if let descriptor = font.fontDescriptor.withSymbolicTraits(.traitBold) {
                    return UIFont(descriptor: descriptor, size: fontSize)
                }
            }
            return font
        }
        return bold ? UIFont.boldSystemFont(ofSize: fontSize) : UIFont.systemFont(ofSize: fontSize)
    }

    private static func parseColor(_ hex: String) -> UIColor {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }

        // AARRGGBB format
        guard hexStr.count == 8, let val = UInt64(hexStr, radix: 16) else {
            return .white
        }

        let a = CGFloat((val >> 24) & 0xFF) / 255.0
        let r = CGFloat((val >> 16) & 0xFF) / 255.0
        let g = CGFloat((val >> 8) & 0xFF) / 255.0
        let b = CGFloat(val & 0xFF) / 255.0
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}
