import Foundation
import Flutter
import UIKit
import PAGAdSDK

// Associated object key used to retain the Pangle related view bound to a container.
private var pangleRelatedViewKey: UInt8 = 0

class NativeAdViewFactory: NSObject, FlutterPlatformViewFactory {
    private weak var handler: PangleAdsHandler?
    
    init(handler: PangleAdsHandler) {
        self.handler = handler
        super.init()
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return NativeAdPlatformView(frame: frame, viewId: viewId, args: args, handler: handler)
    }
    
    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class NativeAdPlatformView: NSObject, FlutterPlatformView {
    private var containerView: UIView
    
    init(frame: CGRect, viewId: Int64, args: Any?, handler: PangleAdsHandler?) {
        containerView = UIView(frame: frame)
        containerView.backgroundColor = .clear
        super.init()
        
        if let args = args as? [String: Any],
           let style = args["style"] as? [String: Any],
           let listenerId = args["listenerId"] as? String,
           let nativeAd = handler?.getNativeAd(listenerId: listenerId) {
            print("[PangleNativeAd] Building native ad view for listenerId: \(listenerId)")
            buildNativeAdView(nativeAd: nativeAd, style: style)
        } else {
            print("[PangleNativeAd] Failed to build view - ad not loaded or invalid args")
        }
    }
    
    func view() -> UIView {
        return containerView
    }
    
    private func buildNativeAdView(nativeAd: PAGLNativeAd, style: [String: Any]) {
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
        let showCallToAction = (style["showCallToAction"] as? Bool) ?? true
        let ctaFontSize = (style["ctaFontSize"] as? Double) ?? 12.0
        let ctaTextColorStr = (style["ctaTextColor"] as? String) ?? "#FFFFFFFF"
        let ctaBgColorStr = (style["ctaBackgroundColor"] as? String) ?? "#FF4285F4"
        let ctaCornerRadiusVal = (style["ctaCornerRadius"] as? Double) ?? 4.0
        let ctaBold = (style["ctaBold"] as? Bool) ?? true
        let ctaPadH = (style["ctaPaddingHorizontal"] as? Double) ?? 8.0
        let layoutMode = (style["layoutMode"] as? String) ?? "horizontal"

        let titleColor = Self.parseColor(titleColorStr)
        let bodyColor = Self.parseColor(bodyColorStr)
        let bgColor = Self.parseColor(bgColorStr)

        // Get native ad data
        let nativeAdData = nativeAd.data
        let title = nativeAdData.adTitle ?? ""
        let description = nativeAdData.adDescription ?? ""
        let callToAction = nativeAdData.buttonText

        // Root view
        let adView = UIView()
        adView.backgroundColor = bgColor
        adView.clipsToBounds = true
        adView.layer.cornerRadius = CGFloat(cornerRadius)
        adView.translatesAutoresizingMaskIntoConstraints = false

        // === Vertical layout branch ===
        if layoutMode == "vertical" {
            let iconUrlStr = nativeAdData.icon.imageURL ?? ""

            // Main image controls (Pangle has only icon, source field is informational)
            let mainImageHeight = (style["mainImageHeight"] as? Double) ?? imageHeight
            let mainImageScaleMode = (style["mainImageScaleMode"] as? String) ?? "cover"
            let mainImageCornerRadiusVal = (style["mainImageCornerRadius"] as? Double) ?? 0.0
            let mainImageBgStr = (style["mainImageBackgroundColor"] as? String) ?? "#00000000"
            let mainImagePadL = (style["mainImagePaddingLeft"] as? Double) ?? 0.0
            let mainImagePadT = (style["mainImagePaddingTop"] as? Double) ?? 0.0
            let mainImagePadR = (style["mainImagePaddingRight"] as? Double) ?? 0.0
            let mainImagePadB = (style["mainImagePaddingBottom"] as? Double) ?? 0.0
            let verticalContentAlignment = (style["verticalContentAlignment"] as? String) ?? "top"

            // Content wrapper to support vertical alignment
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

            // Main image position: use Pangle's PAGMediaView to display the real media
            // (large image / video) so that the main image differs from the small icon.
            let pangleRelatedView = PAGLNativeAdRelatedView()
            pangleRelatedView.refresh(with: nativeAd)
            // Retain the related view for the lifetime of the container.
            objc_setAssociatedObject(
                containerView,
                &pangleRelatedViewKey,
                pangleRelatedView,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )

            let mainImageView: UIView = pangleRelatedView.mediaView
            // mainImageScaleMode is rendered internally by PAGMediaView; kept for API consistency.
            _ = mainImageScaleMode
            mainImageView.backgroundColor = Self.parseColor(mainImageBgStr)
            mainImageView.clipsToBounds = true
            if mainImageCornerRadiusVal > 0 {
                mainImageView.layer.cornerRadius = CGFloat(mainImageCornerRadiusVal)
            }
            mainImageView.translatesAutoresizingMaskIntoConstraints = false
            contentWrapper.addSubview(mainImageView)

            // Small icon (40 × 40)
            let smallIconView = UIImageView()
            smallIconView.contentMode = .scaleAspectFill
            smallIconView.clipsToBounds = true
            if imageCornerRadius > 0 {
                smallIconView.layer.cornerRadius = CGFloat(imageCornerRadius)
            }
            smallIconView.translatesAutoresizingMaskIntoConstraints = false
            if let url = URL(string: iconUrlStr) {
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        DispatchQueue.main.async {
                            smallIconView.image = UIImage(data: data)
                        }
                    }
                }
            }
            contentWrapper.addSubview(smallIconView)

            // Headline
            let vHeadlineLabel = UILabel()
            vHeadlineLabel.font = Self.makeFont(size: titleFontSize, bold: titleBold, family: titleFontFamily)
            vHeadlineLabel.textColor = titleColor
            vHeadlineLabel.numberOfLines = titleMaxLines
            vHeadlineLabel.lineBreakMode = .byTruncatingTail
            vHeadlineLabel.text = title
            vHeadlineLabel.translatesAutoresizingMaskIntoConstraints = false
            contentWrapper.addSubview(vHeadlineLabel)

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

            if showCallToAction && !callToAction.isEmpty {
                let ctaTextColor = Self.parseColor(ctaTextColorStr)
                let ctaBgColor = Self.parseColor(ctaBgColorStr)
                let vCta = PaddedLabel()
                vCta.text = callToAction
                vCta.font = Self.makeFont(size: ctaFontSize, bold: ctaBold, family: nil)
                vCta.textColor = ctaTextColor
                vCta.textAlignment = .center
                vCta.backgroundColor = ctaBgColor
                vCta.layer.cornerRadius = CGFloat(ctaCornerRadiusVal)
                vCta.clipsToBounds = true
                vCta.textInsets = UIEdgeInsets(top: 8, left: CGFloat(ctaPadH), bottom: 8, right: CGFloat(ctaPadH))
                vCta.translatesAutoresizingMaskIntoConstraints = false
                contentWrapper.addSubview(vCta)

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

            containerView.addSubview(adView)
            NSLayoutConstraint.activate([
                adView.topAnchor.constraint(equalTo: containerView.topAnchor),
                adView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
                adView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
                adView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            ])

            // Ad logo at bottom-right (Pangle "广告" badge)
            let adLogoView = pangleRelatedView.logoADImageView
            adLogoView.translatesAutoresizingMaskIntoConstraints = false
            containerView.addSubview(adLogoView)
            NSLayoutConstraint.activate([
                adLogoView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),
                adLogoView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            ])

            nativeAd.registerContainer(containerView, withClickableViews: nil)
            return
        }

        // Icon
        let iconImageView = UIImageView()
        iconImageView.contentMode = .scaleAspectFill
        iconImageView.clipsToBounds = true
        if imageCornerRadius > 0 {
            iconImageView.layer.cornerRadius = CGFloat(imageCornerRadius)
        }
        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        if let url = URL(string: nativeAdData.icon.imageURL ?? "") {
            DispatchQueue.global().async {
                if let data = try? Data(contentsOf: url) {
                    DispatchQueue.main.async {
                        iconImageView.image = UIImage(data: data)
                    }
                }
            }
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

        // CTA
        var ctaLabel: UILabel? = nil
        let hasCta = showCallToAction && !callToAction.isEmpty

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
        if let cta = ctaLabel { textWrapper.addSubview(cta) }

        let bottomAnchorView: UIView = hasCta ? ctaLabel! : bodyLabel

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

        if let cta = ctaLabel {
            constraints.append(cta.trailingAnchor.constraint(equalTo: textWrapper.trailingAnchor))
            constraints.append(cta.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 4))
            constraints.append(cta.heightAnchor.constraint(equalToConstant: CGFloat(ctaFontSize + 10)))
            constraints.append(cta.widthAnchor.constraint(greaterThanOrEqualToConstant: 50))
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

        // Register click interaction
        nativeAd.registerContainer(containerView, withClickableViews: nil)
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
