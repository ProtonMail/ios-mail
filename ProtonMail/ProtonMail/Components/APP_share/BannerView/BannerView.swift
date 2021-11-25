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

    typealias tapAttributedTextActionBlock = () -> Void
    var callback: tapAttributedTextActionBlock?

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
        case black
        
        var backgroundColor: UIColor {
            switch self {
            case .red: return .red
            case .purple: return ColorProvider.BrandNorm
            case .gray: return .lightGray
            case .black: return UIColor(RRGGBB: UInt(0x25272C))
            }
        }

        var textColor: UIColor {
            return .white
        }

        var backgroundAlpha: CGFloat {
            switch self {
            case .red, .purple, .gray:
                return 0.75
            case .black:
                return 1
            }
        }
        
        var fontSize: UIFont {
            switch self {
            case .red, .purple, .gray:
                return UIFont.systemFont(ofSize: 17)
            case .black:
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
         icon: Bool? = false,
         complete: tapAttributedTextActionBlock? = nil)
    {
        self.offset = offset
        self.dismissDuration = dismissDuration

        //super.init(frame: CGRect.zero)
        super.init(frame: CGRect(x: 0, y: 0, width: 343, height: 72))

        self.roundCorners()
        
        self.messageTextview.delegate = self
        self.messageTextview.textContainer.lineFragmentPadding = 0
        self.messageTextview.textContainerInset = .zero
        self.messageTextview.font = appearance.fontSize
        if link == "" {
            self.messageTextview.text = message
            self.messageTextview.textColor = appearance.textColor
        } else {
            self.messageTextview.isScrollEnabled = false
            self.messageTextview.isUserInteractionEnabled = true
            self.messageTextview.isSelectable = true
            self.messageTextview.isEditable = false
            self.messageTextview.dataDetectorTypes = [.link]
            self.messageTextview.attributedText = self.prepareAttributedText(text: message, link: link!)
            self.messageTextview.linkTextAttributes = [.foregroundColor: UIColor.blue]
            
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapAttributedStringHandler(_:)))
            tap.delegate = self
            self.messageTextview.addGestureRecognizer(tap)
            
            self.link = link
            self.callback = complete
        }
        
        //add icon
        if icon! {
            self.addIcon()
            
            /*self.messageTextview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                self.messageTextview.topAnchor.constraint(equalTo: self.topAnchor, constant: 16),
                self.messageTextview.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16),
                self.messageTextview.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 48),
                self.messageTextview.widthAnchor.constraint(equalToConstant: 279),
                self.messageTextview.heightAnchor.constraint(equalToConstant: 40)
            ])*/
        }
        
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

        //self.sizeToFit()
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
        let sizeOfText = self.messageTextview.sizeThatFits(CGSize(width: textViewWidht, height: CGFloat.greatestFiniteMagnitude))

        var buttonHeight = secondButton.frame.height
        if !secondButton.isHidden {
            buttonHeight = buttonHeight + space
        }

        let size = CGSize(width: bannerWidth, height: sizeOfText.height + buttonHeight + yPadding)
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
            callback?()
            /*let value = myTextView.attributedText.attribute(NSAttributedString.Key.link, at: characterIndex, effectiveRange: nil) as! [String:URL]
            let url = value["NSLink"]!
            if (url.absoluteString).starts(with: "downloading") {
                //TODO move to Settings ES screen
            }*/
        }
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
        if link == LocalString._encrypted_search_info_search_partial_link {
            url = URL(string: "partial://")
        } else if link == LocalString._encrypted_search_info_search_downloading_link {
            url = URL(string: "downloading://")
        } else if link == LocalString._encrypted_search_info_search_paused_link {
            url = URL(string: "paused://")
        } else {
            url = URL(string: link)
        }

        let attributes = [NSAttributedString.Key.link: url!] as [NSAttributedString.Key: Any]

        if let subrange = fullString.range(of: link) {
            let range = NSRange(subrange, in: fullString)
            formattedString.addAttribute(.link, value: attributes, range: range)
        }

        //print("formated string: \(formattedString)")
        return formattedString
    }

    private func addIcon() {
        let image = UIImage(named: "ic-exclamation-circle")
        let imageView = UIImageView(image: image!)
        imageView.frame = CGRect(x: 0, y: 0, width: 21, height: 21)
        self.addSubview(imageView)
        
        /*imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: self.topAnchor, constant: 25.5),
            imageView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 25.5),
            imageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 17.5),
            imageView.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -304.5)
        ])*/
    }
}
