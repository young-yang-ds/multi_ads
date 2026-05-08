import Foundation
import Flutter
import UIKit
import VungleAdsSDK

class VungleNativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var handler: VungleAdsHandler?
    
    init(handler: VungleAdsHandler) {
        self.handler = handler
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return VungleNativeAdPlatformView(frame: frame, viewId: viewId, args: args, handler: handler)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class VungleNativeAdPlatformView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    
    init(frame: CGRect, viewId: Int64, args: Any?, handler: VungleAdsHandler?) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        super.init()
        
        if let args = args as? [String: Any],
           let listenerId = args["listenerId"] as? String,
           let style = args["style"] as? [String: Any],
           let nativeAd = handler?.getNativeAd(listenerId: listenerId) {
            print("[VungleNativeAd] Building native ad view for listener: \(listenerId)")
            buildNativeAdView(nativeAd: nativeAd, style: style)
        } else {
            print("[VungleNativeAd] Failed to build view - ad not loaded or invalid args")
        }
    }
    
    func view() -> UIView {
        return containerView
    }
    
    private func buildNativeAdView(nativeAd: VungleNative, style: [String: Any]) {
        // Read style options
        let height = (style["height"] as? Double) ?? 80.0
        let imageWidth = (style["imageWidth"] as? Double) ?? 120.0
        let imageHeight = (style["imageHeight"] as? Double) ?? height
        let titleFontSize = (style["titleFontSize"] as? Double) ?? 14.0
        let titleColorStr = (style["titleColor"] as? String) ?? "#FF202124"
        let titleBold = (style["titleBold"] as? Bool) ?? true
        let titleMaxLines = (style["titleMaxLines"] as? Int) ?? 2
        let titleFontFamily = style["titleFontFamily"] as? String
        let bodyFontSize = (style["bodyFontSize"] as? Double) ?? 10.0
        let bodyColorStr = (style["bodyColor"] as? String) ?? "#FF999999"
        let bodyBold = (style["bodyBold"] as? Bool) ?? false
        let bodyFontFamily = style["bodyFontFamily"] as? String
        let bgColorStr = (style["backgroundColor"] as? String) ?? "#FFFFFFFF"
        let cornerRadius = (style["cornerRadius"] as? Double) ?? 10.0
        let imageCornerRadius = (style["imageCornerRadius"] as? Double) ?? 0.0
        let textPadH = (style["textPaddingHorizontal"] as? Double) ?? 12.0
        let textPadV = (style["textPaddingVertical"] as? Double) ?? 8.0
        let textAlignment = (style["textAlignment"] as? String) ?? "center"
        let showStarRating = (style["showStarRating"] as? Bool) ?? true
        let starSize = (style["starSize"] as? Double) ?? 12.0
        let starActiveColorStr = (style["starActiveColor"] as? String) ?? "#FFFFC107"
        let starInactiveColorStr = (style["starInactiveColor"] as? String) ?? "#FFCCCCCC"
        let showCallToAction = (style["showCallToAction"] as? Bool) ?? true
        let ctaFontSize = (style["ctaFontSize"] as? Double) ?? 12.0
        let ctaTextColorStr = (style["ctaTextColor"] as? String) ?? "#FFFFFFFF"
        let ctaBgColorStr = (style["ctaBackgroundColor"] as? String) ?? "#FF4285F4"
        let ctaCornerRadiusVal = (style["ctaCornerRadius"] as? Double) ?? 4.0
        let ctaBold = (style["ctaBold"] as? Bool) ?? true
        let ctaPadH = (style["ctaPaddingHorizontal"] as? Double) ?? 8.0

        let titleColor = Self.parseColor(titleColorStr)
        let bodyColor = Self.parseColor(bodyColorStr)
        let bgColor = Self.parseColor(bgColorStr)

        // Get native ad data
        let title = nativeAd.title ?? ""
        let description = nativeAd.bodyText ?? ""
        let iconImage = nativeAd.iconImage
        let callToAction = nativeAd.callToAction
        let starRating = nativeAd.adStarRating

        // Root view
        let adView = UIView()
        adView.backgroundColor = bgColor
        adView.clipsToBounds = true
        adView.layer.cornerRadius = CGFloat(cornerRadius)
        adView.translatesAutoresizingMaskIntoConstraints = false

        // Icon
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        if imageCornerRadius > 0 {
            iconImageView.layer.cornerRadius = CGFloat(imageCornerRadius)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        if let iconImage = iconImage {
            iconImageView.image = iconImage
        }
        adView.addSubview(iconImageView)

        // Headline
        let headlineLabel = UILabel()
        headlineLabel.font = Self.makeFont(size: titleFontSize, bold: titleBold, family: titleFontFamily)
        headlineLabel.textColor = titleColor
        headlineLabel.numberOfLines = titleMaxLines
        headlineLabel.lineBreakMode = .byTruncatingTail
        headlineLabel.text = title
        headlineLabel.translatesAutoresizingMaskIntoConstraints = false

        // Body
        let bodyLabel = UILabel()
        bodyLabel.font = Self.makeFont(size: bodyFontSize, bold: bodyBold, family: bodyFontFamily)
        bodyLabel.textColor = bodyColor
        bodyLabel.numberOfLines = 1
        bodyLabel.lineBreakMode = .byTruncatingTail
        bodyLabel.text = description
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false

        // Bottom row elements
        let hasStarRating = showStarRating && starRating > 0
        let hasCta = showCallToAction && !callToAction.isEmpty

        var starsLabel: UILabel? = nil
        var ctaLabel: UILabel? = nil

        if hasStarRating {
            let starActiveColor = Self.parseColor(starActiveColorStr)
            let starInactiveColor = Self.parseColor(starInactiveColorStr)
            let rating = Int(starRating)
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
            starsLabel = label
        }

        if hasCta {
            let ctaTextColor = Self.parseColor(ctaTextColorStr)
            let ctaBgColor = Self.parseColor(ctaBgColorStr)
            let label = PaddedLabel()
            label.text = callToAction
            label.font = Self.makeFont(size: ctaFontSize, bold: ctaBold, family: nil)
            label.textColor = ctaTextColor
            label.textAlignment = .center
            label.backgroundColor = ctaBgColor
            label.layer.cornerRadius = CGFloat(ctaCornerRadiusVal)
            label.clipsToBounds = true
            label.textInsets = UIEdgeInsets(top: 0, left: CGFloat(ctaPadH), bottom: 0, right: CGFloat(ctaPadH))
            label.translatesAutoresizingMaskIntoConstraints = false
            ctaLabel = label
        }

        // Text wrapper
        let textWrapper = UIView()
        textWrapper.translatesAutoresizingMaskIntoConstraints = false
        adView.addSubview(textWrapper)
        textWrapper.addSubview(headlineLabel)
        textWrapper.addSubview(bodyLabel)
        if let stars = starsLabel { textWrapper.addSubview(stars) }
        if let cta = ctaLabel { textWrapper.addSubview(cta) }

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

        containerView.addSubview(adView)
        NSLayoutConstraint.activate([
            adView.topAnchor.constraint(equalTo: containerView.topAnchor),
            adView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            adView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            adView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
        ])

        // Register view for interaction
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            let mediaView = MediaView()
            nativeAd.registerViewForInteraction(
                view: containerView,
                mediaView: mediaView,
                iconImageView: iconImageView,
                viewController: rootVC,
                clickableViews: [containerView]
            )
        }
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
