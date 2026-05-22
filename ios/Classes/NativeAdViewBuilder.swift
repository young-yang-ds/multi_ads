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
        let imageCornerRadius = (options["imageCornerRadius"] as? Double) ?? 0.0
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
        let ctaPadH = (options["ctaPaddingHorizontal"] as? Double) ?? 8.0
        let layoutMode = (options["layoutMode"] as? String) ?? "horizontal"

        let titleColor = parseColor(titleColorStr)
        let bodyColor = parseColor(bodyColorStr)
        let bgColor = parseColor(bgColorStr)

        // NativeAdView
        let adView = NativeAdView()
        adView.backgroundColor = bgColor
        adView.clipsToBounds = true
        adView.layer.cornerRadius = CGFloat(cornerRadius)

        // === Vertical layout branch (full-screen native ad) ===
        if layoutMode == "vertical" {
            // Main image controls
            let mainImageHeight = (options["mainImageHeight"] as? Double) ?? imageHeight
            let mainImageScaleMode = (options["mainImageScaleMode"] as? String) ?? "cover"
            let mainImageCornerRadiusVal = (options["mainImageCornerRadius"] as? Double) ?? 0.0
            let mainImageBgStr = (options["mainImageBackgroundColor"] as? String) ?? "#00000000"
            let mainImageSource = (options["mainImageSource"] as? String) ?? "auto"
            let mainImagePadL = (options["mainImagePaddingLeft"] as? Double) ?? 0.0
            let mainImagePadT = (options["mainImagePaddingTop"] as? Double) ?? 0.0
            let mainImagePadR = (options["mainImagePaddingRight"] as? Double) ?? 0.0
            let mainImagePadB = (options["mainImagePaddingBottom"] as? Double) ?? 0.0
            let verticalContentAlignment = (options["verticalContentAlignment"] as? String) ?? "top"

            // Content wrapper to support vertical alignment (top/center/bottom)
            let contentWrapper = UIView()
            contentWrapper.translatesAutoresizingMaskIntoConstraints = false
            adView.addSubview(contentWrapper)

            var wrapperConstraints: [NSLayoutConstraint] = [
                contentWrapper.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
                contentWrapper.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
            ]
            switch verticalContentAlignment {
            case "center":
                wrapperConstraints += [
                    contentWrapper.centerYAnchor.constraint(equalTo: adView.centerYAnchor),
                    contentWrapper.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor),
                    contentWrapper.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor),
                ]
            case "bottom":
                wrapperConstraints += [
                    contentWrapper.bottomAnchor.constraint(equalTo: adView.bottomAnchor),
                    contentWrapper.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor),
                ]
            default:
                wrapperConstraints += [
                    contentWrapper.topAnchor.constraint(equalTo: adView.topAnchor),
                    contentWrapper.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor),
                ]
            }
            NSLayoutConstraint.activate(wrapperConstraints)

            // Main image (full width × mainImageHeight)
            let mainImageView = UIImageView()
            switch mainImageScaleMode {
            case "contain": mainImageView.contentMode = .scaleAspectFit
            case "fill":    mainImageView.contentMode = .scaleToFill
            default:        mainImageView.contentMode = .scaleAspectFill
            }
            mainImageView.backgroundColor = parseColor(mainImageBgStr)
            mainImageView.clipsToBounds = true
            if mainImageCornerRadiusVal > 0 {
                mainImageView.layer.cornerRadius = CGFloat(mainImageCornerRadiusVal)
            }
            mainImageView.translatesAutoresizingMaskIntoConstraints = false
            contentWrapper.addSubview(mainImageView)
            adView.iconView = mainImageView

            // Image source: auto / media / icon
            switch mainImageSource {
            case "media":
                mainImageView.image = nativeAd.images?.first?.image
            case "icon":
                mainImageView.image = nativeAd.icon?.image
            default:
                if let firstImage = nativeAd.images?.first?.image {
                    mainImageView.image = firstImage
                } else if let icon = nativeAd.icon?.image {
                    mainImageView.image = icon
                }
            }

            // Small icon (40 × 40)
            let smallIconView = UIImageView()
            smallIconView.contentMode = .scaleAspectFill
            smallIconView.clipsToBounds = true
            if imageCornerRadius > 0 {
                smallIconView.layer.cornerRadius = CGFloat(imageCornerRadius)
            }
            smallIconView.translatesAutoresizingMaskIntoConstraints = false
            if let icon = nativeAd.icon?.image {
                smallIconView.image = icon
            }
            contentWrapper.addSubview(smallIconView)

            // Headline
            let vHeadlineLabel = UILabel()
            vHeadlineLabel.font = makeFont(size: titleFontSize, bold: titleBold, family: titleFontFamily)
            vHeadlineLabel.textColor = titleColor
            vHeadlineLabel.numberOfLines = titleMaxLines
            vHeadlineLabel.lineBreakMode = .byTruncatingTail
            vHeadlineLabel.text = nativeAd.headline
            vHeadlineLabel.translatesAutoresizingMaskIntoConstraints = false
            contentWrapper.addSubview(vHeadlineLabel)
            adView.headlineView = vHeadlineLabel

            var vConstraints: [NSLayoutConstraint] = [
                mainImageView.topAnchor.constraint(equalTo: contentWrapper.topAnchor, constant: CGFloat(mainImagePadT)),
                mainImageView.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: CGFloat(mainImagePadL)),
                mainImageView.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor, constant: -CGFloat(mainImagePadR)),
                mainImageView.heightAnchor.constraint(equalToConstant: CGFloat(mainImageHeight)),

                smallIconView.topAnchor.constraint(equalTo: mainImageView.bottomAnchor, constant: CGFloat(mainImagePadB + textPadV)),
                smallIconView.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: CGFloat(textPadH)),
                smallIconView.widthAnchor.constraint(equalToConstant: 40),
                smallIconView.heightAnchor.constraint(equalToConstant: 40),

                vHeadlineLabel.leadingAnchor.constraint(equalTo: smallIconView.trailingAnchor, constant: 8),
                vHeadlineLabel.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor, constant: -CGFloat(textPadH)),
                vHeadlineLabel.centerYAnchor.constraint(equalTo: smallIconView.centerYAnchor),
            ]

            // Full-width CTA
            if showCallToAction, let ctaText = nativeAd.callToAction {
                let ctaTextColor = parseColor(ctaTextColorStr)
                let ctaBgColor = parseColor(ctaBgColorStr)
                let vCta = PaddedLabel()
                vCta.text = ctaText
                vCta.font = makeFont(size: ctaFontSize, bold: ctaBold, family: nil)
                vCta.textColor = ctaTextColor
                vCta.textAlignment = .center
                vCta.backgroundColor = ctaBgColor
                vCta.layer.cornerRadius = CGFloat(ctaCornerRadiusVal)
                vCta.clipsToBounds = true
                vCta.textInsets = UIEdgeInsets(top: 8, left: CGFloat(ctaPadH), bottom: 8, right: CGFloat(ctaPadH))
                vCta.translatesAutoresizingMaskIntoConstraints = false
                contentWrapper.addSubview(vCta)
                adView.callToActionView = vCta

                vConstraints += [
                    vCta.topAnchor.constraint(equalTo: smallIconView.bottomAnchor, constant: CGFloat(textPadV)),
                    vCta.leadingAnchor.constraint(equalTo: contentWrapper.leadingAnchor, constant: CGFloat(textPadH)),
                    vCta.trailingAnchor.constraint(equalTo: contentWrapper.trailingAnchor, constant: -CGFloat(textPadH)),
                    vCta.bottomAnchor.constraint(equalTo: contentWrapper.bottomAnchor, constant: -CGFloat(textPadV)),
                ]
            } else {
                vConstraints += [
                    smallIconView.bottomAnchor.constraint(equalTo: contentWrapper.bottomAnchor, constant: -CGFloat(textPadV)),
                ]
            }

            NSLayoutConstraint.activate(vConstraints)
            adView.nativeAd = nativeAd
            return adView
        }

        // Thumbnail
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        if imageCornerRadius > 0 {
            iconImageView.layer.cornerRadius = CGFloat(imageCornerRadius)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(iconImageView)
        adView.iconView = iconImageView

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.font = makeFont(size: titleFontSize, bold: titleBold, family: titleFontFamily)
        headlineLabel.textColor = titleColor
        headlineLabel.numberOfLines = titleMaxLines
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(headlineLabel)
        adView.headlineView = headlineLabel

        // Body
        let bodyLabel = UILabel()
        bodyLabel.font = makeFont(size: bodyFontSize, bold: bodyBold, family: bodyFontFamily)
        bodyLabel.textColor = bodyColor
        bodyLabel.numberOfLines = 1
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
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
            let label = PaddedLabel()
            label.text = callToAction
            label.font = makeFont(size: ctaFontSize, bold: ctaBold, family: nil)
            label.textColor = ctaTextColor
            label.textAlignment = .center
            label.backgroundColor = ctaBgColor
            label.layer.cornerRadius = CGFloat(ctaCornerRadiusVal)
            label.clipsToBounds = true
            label.textInsets = UIEdgeInsets(top: 0, left: CGFloat(ctaPadH), bottom: 0, right: CGFloat(ctaPadH))
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
            let centerY = textWrapper.centerYAnchor.constraint(equalTo: adView.centerYAnchor)
            centerY.priority = .defaultHigh
            constraints += [
                centerY,
                textWrapper.topAnchor.constraint(greaterThanOrEqualTo: adView.topAnchor),
                textWrapper.bottomAnchor.constraint(lessThanOrEqualTo: adView.bottomAnchor),
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
