//
//  TopMessageView.swift
//  Proton Mail - Created on 6/3/16.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit
import ProtonCore_UIFoundations

class BannerView: PMView {

    let yourAttributes: [NSAttributedString.Key: Any] = [
        .font: UIFont.preferredFont(forTextStyle: .footnote),
        .foregroundColor: UIColor.white,
        .underlineStyle: NSUnderlineStyle.single.rawValue]
    // .double.rawValue, .thick.rawValue
    private weak var superView: UIView!
    private var animator: UIDynamicAnimator!
    private var springBehavior: UIAttachmentBehavior!
    private var offset: CGFloat
    private var dismissDuration: TimeInterval
    private var timer: Timer?
    private var buttonConfig: ButtonConfiguration?
    private var secondButtonConfig: ButtonConfiguration?
    private var link: String? = ""
    private var appearance: Appearance?
    private var icon: UIImageView? = nil
    private var messageLabel: UILabel? = nil

    typealias tapAttributedTextActionBlock = () -> Void
    var callback: tapAttributedTextActionBlock?
    var handleAttributedTextTap: tapAttributedTextActionBlock?
    typealias dismissActionBlock = () -> Void
    var dismissAction: dismissActionBlock?

    @IBOutlet private weak var button: UIButton!
    @IBOutlet private var backgroundView: UIView!
    @IBOutlet private var messageTextview: UITextView!
    @IBOutlet weak var secondButton: UIButton!

    override func getNibName() -> String {
        return "\(BannerView.self)"
    }

    @IBAction func closeAction(_ sender: UIButton) {
        self.buttonConfig?.action?()
    }
    @IBAction func secondAction(_ sender: Any) {
        self.secondButtonConfig?.action?()
    }

    enum Appearance {
        case red // TODO: rename according to semantic, not appearance
        case purple
        case gray
        case esBlack
        case esGray
        
        var backgroundColor: UIColor {
            switch self {
            case .red: return .red
            case .purple: return ColorProvider.BrandNorm
            case .gray: return .lightGray
            case .esBlack: return UIColor.dynamic(light: UIColor(RRGGBB: UInt(0x25272C)), dark: ColorProvider.BackgroundNorm)
            case .esGray: return ColorProvider.BackgroundSecondary
            }
        }

        var textColor: UIColor {
            switch self {
            case .red, .purple, .gray, .esBlack:
                return .white
            case .esGray:
                return ColorProvider.TextWeak
            }
        }

        var backgroundAlpha: CGFloat {
            switch self {
            case .red, .purple, .gray:
                return 0.75
            case .esBlack, .esGray:
                return 1
            }
        }
        
        var fontSize: UIFont {
            switch self {
            case .red, .purple, .gray:
                return UIFont.systemFont(ofSize: 17)
            case .esBlack, .esGray:
                return UIFont.systemFont(ofSize: 14)
            }
        }
    }

    enum Base {
        case top, bottom
    }

    struct ButtonConfiguration {
        let title: String
        let action: (() -> Void)?
    }

    init(appearance: Appearance,
         message: String,
         buttons: ButtonConfiguration?,
         button2: ButtonConfiguration? = nil,
         offset: CGFloat,
         dismissDuration: TimeInterval = 4,
         link: String? = "",
         handleAttributedTextTap: tapAttributedTextActionBlock? = nil,
         dismissAction: dismissActionBlock? = nil)
    {
        self.offset = offset
        self.dismissDuration = dismissDuration

        self.appearance = appearance
        self.dismissAction = dismissAction

        super.init(frame: CGRect.zero)

        self.roundCorners()

        self.messageTextview.delegate = self
        self.messageTextview.textContainer.lineFragmentPadding = 0
        self.messageTextview.textContainerInset = .zero
        self.messageTextview.font = appearance.fontSize
        self.messageTextview.isScrollEnabled = false
        self.messageTextview.isEditable = false
        if link == "" {
            self.messageTextview.text = message
            self.messageTextview.textColor = appearance.textColor
        } else {
            self.messageTextview.isUserInteractionEnabled = true
            self.messageTextview.isSelectable = true
            self.messageTextview.dataDetectorTypes = [.link]
            self.messageTextview.attributedText = self.prepareAttributedText(text: message, link: link!)
            self.messageTextview.linkTextAttributes = [.foregroundColor: ColorProvider.BrandNorm]
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAttributedStringHandler(_:)))
            tap.delegate = self
            self.messageTextview.addGestureRecognizer(tap)
            
            self.link = link
            self.handleAttributedTextTap = handleAttributedTextTap
        }

        self.messageLabel = UILabel()
        self.messageLabel?.isHidden = true
        self.messageLabel?.text = message
        self.addSubview(self.messageLabel!)

        self.backgroundView.backgroundColor = appearance.backgroundColor
        self.backgroundView.alpha = appearance.backgroundAlpha
        self.buttonConfig = buttons

        if let config = buttons {
            self.button.isHidden = false
            self.button.setTitle(config.title, for: .normal)
        } else {
            self.button.isHidden = true
        }

        self.secondButtonConfig = button2
        if let _ = button2 {
            let attributed = NSMutableAttributedString(string: "\(message) ", attributes: [NSAttributedString.Key.foregroundColor: appearance.textColor, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 17)])
            let troubleAttribute = NSAttributedString(string: "Troubleshoot", attributes: [NSAttributedString.Key.link: "troubleshoot://"])
            attributed.append(troubleAttribute)
            self.messageTextview.attributedText = attributed
            self.messageTextview.linkTextAttributes = yourAttributes
        }

        self.messageTextview.sizeToFit()
        self.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(onPan(gesture:))))

        self.sizeToFit()
        self.layoutIfNeeded()
    }

    required init?(coder aDecoder: NSCoder) {
        self.offset = 0
        self.dismissDuration = 0
        super.init(coder: aDecoder)
    }
}

extension BannerView: UIGestureRecognizerDelegate {

    func drop(on baseView: UIView, from: Base) {
        self.superView = baseView

        // sizing
        let xPadding: CGFloat = 16.0
        let yPadding: CGFloat = 12.0
        let space: CGFloat = 2 * 8.0
        let bannerWidth: CGFloat = baseView.bounds.width - 2 * xPadding
        let horizontalStackWidth: CGFloat = bannerWidth - 20 - 20
        let verticalStackWidth: CGFloat = horizontalStackWidth - 41 - 8
        let textViewWidht = verticalStackWidth - 20

        if self.appearance == .esBlack {
            self.addIcon()
        }

        let sizeOfText: CGSize = self.messageTextview.sizeThatFits(CGSize(width: textViewWidht, height: CGFloat.greatestFiniteMagnitude))

        var buttonHeight = secondButton.frame.height
        if !secondButton.isHidden {
            buttonHeight = buttonHeight + space
        }

        var bannerHeight: CGFloat = 0.0
        if self.appearance == .esGray {
            self.messageTextview.font = self.appearance?.fontSize
            self.messageTextview.textColor = self.appearance?.textColor
            bannerHeight = 92.0//self.messageTextview.bounds.height + (2 * 16.0)    //TODO banner height wrong when more than one line
        } else if self.appearance == .esBlack {
            self.messageTextview.font = self.appearance?.fontSize
            self.messageTextview.textColor = self.appearance?.textColor
            bannerHeight = 72.0//self.messageTextview.bounds.height + (2 * 16.0)
        } else {
            let sizeOfText: CGSize = self.messageTextview.sizeThatFits(CGSize(width: textViewWidht, height: CGFloat.greatestFiniteMagnitude))
            bannerHeight = sizeOfText.height + buttonHeight + yPadding
        }
        
        let size = CGSize(width: bannerWidth, height: bannerHeight)

        self.frame = CGRect(origin: .zero, size: size)
        let initAnchor = CGPoint(x: (baseView.bounds.width / 2),
                                 y: from == .bottom ? (baseView.bounds.height - self.bounds.height / 2) - offset
                                    : (self.bounds.height / 2) + offset)
        // if directly assign to this value, it could be removed from the other function. looks like it is not thread-safe
        let dyAnimator = UIDynamicAnimator(referenceView: baseView)
        self.animator = dyAnimator

        // original location
        self.center = initAnchor.applying(CGAffineTransform(translationX: 0, y: from == .bottom ? (baseView.bounds.height - initAnchor.y)
            : (-initAnchor.y)))

        let springBehavior = UIAttachmentBehavior(item: self, attachedToAnchor: initAnchor)
        springBehavior.length = 0
        springBehavior.damping = 0.9
        springBehavior.frequency = 2
        dyAnimator.addBehavior(springBehavior)
        self.springBehavior = springBehavior

        // Set some constraints
        if self.appearance == .esGray {
            self.messageTextview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.messageTextview.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                self.messageTextview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                self.messageTextview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -48),
                self.messageTextview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
            ])

            // Add dismiss icon + callback
            if let image = UIImage(named: "mail_label_cross_icon") {
                let tintableImage = image.withRenderingMode(.alwaysTemplate)
                let imageView = UIImageView(image: tintableImage)
                imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                imageView.tintColor = ColorProvider.IconWeak
                imageView.isUserInteractionEnabled = true
                let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
                imageView.addGestureRecognizer(tapRecognizer)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 34),
                    imageView.leadingAnchor.constraint(equalTo: self.messageTextview.trailingAnchor, constant: 8),
                    imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                    imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -34)
                ])
            }
        } else if self.appearance == .esBlack {
            // Set constraints for the text
            self.messageTextview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.messageTextview.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                self.messageTextview.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 48),
                self.messageTextview.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                self.messageTextview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
            ])
            // Set constraints for icon
            self.icon?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.icon!.topAnchor.constraint(equalTo: self.topAnchor, constant: 24),
                self.icon!.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
                self.icon!.trailingAnchor.constraint(equalTo: self.messageTextview.leadingAnchor, constant: -8),
                self.icon!.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -24)
            ])
        }

        UIView.animate(withDuration: 0.3,
                       delay: 0,
                       usingSpringWithDamping: 0.7,
                       initialSpringVelocity: 0.1,
                       options: [.curveEaseIn],
                       animations: {
                        self.center = initAnchor
        }) { _ in
            self.startTimer()
        }
    }

    func displayBanner(on baseView: UIView) {
        self.superView = baseView

        // sizing
        let xPadding: CGFloat = 16.0
        let yPadding: CGFloat = 12.0
        let space: CGFloat = 2 * 8.0
        let bannerWidth: CGFloat = baseView.bounds.width - 2 * xPadding
        let horizontalStackWidth: CGFloat = bannerWidth - 20 - 20
        let verticalStackWidth: CGFloat = horizontalStackWidth - 41 - 8
        let textViewWidht = verticalStackWidth - 20
        if self.appearance == .esBlack {
            self.addIcon()
        }

        var buttonHeight = secondButton.frame.height
        if !secondButton.isHidden {
            buttonHeight = buttonHeight + space
        }

        var bannerHeight: CGFloat = 0.0
        if self.appearance == .esGray {
            self.messageTextview.font = self.appearance?.fontSize
            self.messageTextview.textColor = self.appearance?.textColor

            let sizeOfText: CGSize = self.messageTextview.sizeThatFits(CGSize(width: textViewWidht, height: CGFloat.greatestFiniteMagnitude))

            let numberOfLines = Int(sizeOfText.height / (self.appearance?.fontSize.lineHeight ?? 1.0))
            if numberOfLines == 1 {
                self.messageTextview.textAlignment = .center
            }

            // number of lines + padding top/bottom + some extra space
            bannerHeight = (CGFloat(numberOfLines) * (self.appearance?.fontSize.lineHeight ?? 1.0)) + (2 * 16.0) + 4.0
        } else if self.appearance == .esBlack {
            self.messageTextview.font = self.appearance?.fontSize
            self.messageTextview.textColor = self.appearance?.textColor
            bannerHeight = 72.0//self.messageTextview.bounds.height + (2 * 16.0)
        } else {
            let sizeOfText: CGSize = self.messageTextview.sizeThatFits(CGSize(width: textViewWidht, height: CGFloat.greatestFiniteMagnitude))
            bannerHeight = sizeOfText.height + buttonHeight + yPadding
        }

        let size = CGSize(width: bannerWidth, height: bannerHeight)
        self.frame = CGRect(origin: .zero, size: size)
        self.center = CGPoint(x: (baseView.bounds.width / 2), y: self.offset + bannerHeight/2)

        // Set some constraints
        if self.appearance == .esGray {
            self.messageTextview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.messageTextview.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: -8),
                //self.messageTextview.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.messageTextview.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                self.messageTextview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
            ])

            // Add dismiss icon + callback
            if let image = UIImage(named: "mail_label_cross_icon") {
                let tintableImage = image.withRenderingMode(.alwaysTemplate)
                let imageView = UIImageView(image: tintableImage)
                imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
                imageView.tintColor = ColorProvider.IconWeak
                imageView.isUserInteractionEnabled = true
                let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismiss))
                imageView.addGestureRecognizer(tapRecognizer)
                imageView.translatesAutoresizingMaskIntoConstraints = false
                self.addSubview(imageView)
                NSLayoutConstraint.activate([
                    imageView.leadingAnchor.constraint(equalTo: self.messageTextview.trailingAnchor, constant: 8),
                    imageView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -16),
                    imageView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                    imageView.widthAnchor.constraint(equalToConstant: 24),
                    imageView.heightAnchor.constraint(equalToConstant: 24)
                ])
            }
        } else if self.appearance == .esBlack {
            // Use a label instead of the uitextview - set constraints
            self.messageTextview.isHidden = true
            self.messageLabel?.isHidden = false
            self.messageLabel?.textColor = self.appearance?.textColor
            self.messageLabel?.font = self.appearance?.fontSize
            self.messageLabel?.numberOfLines = 2
            self.messageLabel?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.messageLabel!.centerXAnchor.constraint(equalTo: self.centerXAnchor, constant: 16),
                self.messageLabel!.centerYAnchor.constraint(equalTo: self.centerYAnchor)
            ])
            if bannerWidth <= 396 {
                NSLayoutConstraint.activate([
                    self.messageLabel!.widthAnchor.constraint(equalToConstant: bannerWidth - 48 - 16)
                ])
            }

            // Set constraints for icon
            self.icon?.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.icon!.trailingAnchor.constraint(equalTo: self.messageLabel!.leadingAnchor, constant: -8),
                self.icon!.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                self.icon!.widthAnchor.constraint(equalToConstant: 21),
                self.icon!.heightAnchor.constraint(equalToConstant: 21)
            ])
        }
    }

    @objc func remove(animated: Bool) {
        self.invalidateTimer()
        self.springBehavior = nil
        self.animator = nil

        guard let superView = self.superView else {
            self.removeFromSuperview()
            return
        }

        UIView.animate(withDuration: 0.5, delay: 0, options: [.curveEaseInOut], animations: { [weak self] in
            guard let self = self else { return }
            self.alpha = 0
            if self.center.y < (superView.bounds.height / 2) {
                self.center = self.center.applying(CGAffineTransform(translationX: 0,
                                                                     y: -self.center.y - self.bounds.height))
            } else {
                self.center = self.center.applying(CGAffineTransform(translationX: 0,
                                                                     y: superView.bounds.height + self.bounds.height))
            }
            }, completion: { [weak self] _ in
                self?.removeFromSuperview()
        })
    }

    func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: self.dismissDuration, target: self, selector: #selector(remove(animated:)), userInfo: nil, repeats: false)
    }

    func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    @objc func onPan(gesture: UIPanGestureRecognizer) {
        guard let referenceView = self.animator?.referenceView else { return }

        switch gesture.state {
        case .began:
            self.invalidateTimer()
            self.animator.removeBehavior(self.springBehavior)

        case .changed:
            let anchor = self.springBehavior.anchorPoint
            let translation = gesture.translation(in: referenceView).y

            var y: CGFloat
            let left = (self.superView.bounds.height / 2) - self.center.y
            let right = (self.superView.bounds.height / 2) - self.center.y + translation
            if left < right {
                let unboundedY = anchor.y + translation
                y = rubberBandDistance( offset: unboundedY - anchor.y, dimension: referenceView.bounds.height - anchor.y)
            } else {
                y = translation
            }
            self.center = CGPoint(x: anchor.x, y: y + anchor.y)

        case .ended, .cancelled, .failed:
            let velocity = gesture.velocity(in: referenceView).y
            let duration: TimeInterval = 0.3
            let finalY = velocity * CGFloat(duration) + self.center.y
            if finalY < 0 || finalY > referenceView.bounds.height {
                UIView.animate(withDuration: duration, animations: {
                    var center = self.center
                    center.y = finalY
                    self.center = center
                }) { _ in
                    self.removeFromSuperview()
                }
            } else {
                self.startTimer()
                self.animator.addBehavior(self.springBehavior)
            }
        default: break
        }
    }

    internal func rubberBandDistance(offset: CGFloat, dimension: CGFloat) -> CGFloat {
        let constant: CGFloat = 0.55
        let absOffset = abs(offset)
        let result = (constant * absOffset * dimension) / (dimension + constant * absOffset)
        return offset < 0 ? -result : result
    }
    
    @objc func tapAttributedStringHandler(_ sender: UITapGestureRecognizer) {
        let myTextView = sender.view as! UITextView
        let layoutManager = myTextView.layoutManager
        
        var location = sender.location(in: myTextView)
        location.x -= myTextView.textContainerInset.left
        location.y -= myTextView.textContainerInset.right
        
        let text = myTextView.attributedText.string
        let subrange = text.range(of: self.link!)
        let range = NSRange(subrange!, in: text)
        
        let characterIndex = layoutManager.characterIndex(for: location, in: myTextView.textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        if range.contains(characterIndex) {
            self.handleAttributedTextTap?()
            /*let value = myTextView.attributedText.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) as! [String:URL]
            let url = value["NSLink"]!
            if (url.absoluteString).starts(with: "downloading") {
                //TODO move to Settings ES screen
            }*/
        }
    }
    
    @objc func dismiss(_ sender: UITapGestureRecognizer) {
        self.remove(animated: true)
        self.dismissAction?()
    }
}

extension BannerView: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        if URL.absoluteString.starts(with: "troubleshoot") {
            self.secondAction("")
        }
        return false
    }
}

extension BannerView {
    func prepareAttributedText(text: String, link: String) -> NSMutableAttributedString {
        let fullString = String.localizedStringWithFormat(text, link)
        let formattedString = NSMutableAttributedString(string: fullString)

        var url: URL? = nil
        if link == LocalString._encrypted_search_info_search_downloading_link {
            url = URL(string: "downloading://")
        } else if link == LocalString._encrypted_search_banner_slow_search_link {
            url = URL(string: "slowsearch://")
        } else if link == LocalString._encrypted_search_info_search_paused_link {
                url = URL(string: "paused://")
        } else if link == LocalString._encrypted_search_info_search_partial_link {
                url = URL(string: "partial://")
        } else {
            url = URL(string: link)
        }

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.link: url!
        ]

        if let subrange = fullString.range(of: link) {
            let range = NSRange(subrange, in: fullString)
            formattedString.addAttribute(.link, value: attributes, range: range)
        }

        return formattedString
    }

    private func addIcon() {
        if let image = UIImage(named: "ic-exclamation-circle") {
            let tintableImage = image.withRenderingMode(.alwaysTemplate)
            self.icon = UIImageView(image: tintableImage)
            self.icon!.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
            self.icon!.tintColor = UIColor.dynamic(light: ColorProvider.IconInverted, dark: UIColor(RRGGBB: UInt(0xFFFFFF)))
            self.addSubview(self.icon!)
        }
    }
}
