//
//  PMBanner.swift
//  ProtonCore-UIFoundations - Created on 31.08.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

public class PMBanner: UIView {

    // MARK: Constants
    private let BORDER_PADDING: CGFloat = 8
    private let ICON_SIZE: CGFloat = 32
    private let ANIMATE_DURATION: TimeInterval = 0.25

    // MARK: Private Variables
    private let message: String?
    private let attributedString: NSAttributedString?
    private let icon: UIImage?
    private let style: PMBannerStyleProtocol
    private let dismissDuration: TimeInterval
    private var iconButton: UIImage?
    private var iconButtonHandler: ((PMBanner) -> Void)?
    private var textButton: String?
    private var textButtonHandler: ((PMBanner) -> Void)?
    private var textView: UITextView?
    private var linkAttributed: [NSAttributedString.Key: Any]?
    private var linkHandler: ((PMBanner, URL) -> Void)?
    private var position: PMBannerPosition?
    private var timer: Timer?
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var initLocation: CGPoint = .zero
    private var lastLocation: CGPoint = .zero

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Initialize `PMBanner`
    /// - Parameters:
    ///   - message: Banner message
    ///   - style: Banner style
    ///   - icon: Banner icon that show on top-left
    ///   - dismissDuration: Banner will dismis after `dismissDuration` seconds, `Double.infinity` means never dismiss automatically
    public convenience init(message: String,
                            style: PMBannerStyleProtocol,
                            icon: UIImage? = nil,
                            dismissDuration: TimeInterval = 4) {
        self.init(style: style, message: message, dismissDuration: dismissDuration, icon: icon)
    }

    /// Initialize `PMBanner`
    /// - Parameters:
    ///   - message: Banner message
    ///   - style: Banner style
    ///   - icon: Banner icon that show on top-left
    ///   - dismissDuration: Banner will dismis after `dismissDuration` seconds, `Double.infinity` means never dismiss automatically
    public convenience init(message: NSAttributedString,
                            style: PMBannerStyleProtocol,
                            icon: UIImage? = nil,
                            dismissDuration: TimeInterval = 4) {
        self.init(style: style, message: nil, dismissDuration: dismissDuration, attributedString: message, icon: icon)
    }

    private init(style: PMBannerStyleProtocol,
                 message: String?,
                 dismissDuration: TimeInterval = 4,
                 attributedString: NSAttributedString? = nil,
                 icon: UIImage? = nil) {
        self.style = style
        self.dismissDuration = dismissDuration
        self.message = message
        self.attributedString = attributedString
        self.icon = icon
        super.init(frame: .zero)
        self.backgroundColor = style.bannerColor
        self.roundCorner(style.borderRadius)
        self.setupPanGesture()
    }

    deinit {
        self.unsubscribeNotification()
    }
}

// MARK: Public function
extension PMBanner {

    /// Add an icon button on top-right
    /// - Parameters:
    ///   - icon: Icon of button
    ///   - handler: A block to execute when the user clicks the button.
    public func addButton(icon: UIImage, handler: ((PMBanner) -> Void)?) {
        self.iconButton = icon
        self.iconButtonHandler = handler
    }

    /// Add a text button on bottom-right
    /// - Parameters:
    ///   - icon: Icon of button
    ///   - handler: A block to execute when the user clicks the button.
    public func addButton(text: String, handler: ((PMBanner) -> Void)?) {
        self.textButton = text
        self.textButtonHandler = handler
    }

    /// Add appearance style and handler for link seted by `NSAttributedString`
    /// - Parameters:
    ///   - linkAttributed: Appearance style of link
    ///   - linkHandler: A block to execute when the user clicks the link.
    public func add(linkAttributed: [NSAttributedString.Key: Any]?, linkHandler: @escaping ((PMBanner, URL) -> Void)) {
        self.linkAttributed = linkAttributed
        self.linkHandler = linkHandler
    }

    /// Show `PMBanner` at a specific position on given `UIViewController`
    /// - Parameters:
    ///   - position: Position that `PMBanner` will show
    ///   - parent: `UIViewController` that `PMBanner` will show
    public func show(at position: PMBannerPosition, on parent: UIViewController, ignoreKeyboard: Bool = false) {

        self.setupElements()
        self.position = position
        parent.view.addSubview(self)
        self.setupBannerConstraint(position: position, parent: parent.view)
        self.setupDismissTimer(duration: self.dismissDuration)
        parent.view.layoutIfNeeded()
        self.showAnimate(ignoreKeyboard: ignoreKeyboard)
        self.subscribeNotification()
    }

    /// Dismiss this `PMBanner` manually
    public func dismiss(animated: Bool = true) {
        self.invalidateTimer()
        runInMainThread {
            guard animated else {
                self.removeFromSuperview()
                return
            }
            self.dismissAnimate()
        }
    }

    /// Dismiss all `PMBanner` shown on given `UIViewController`
    public static func dismissAll(on parent: UIViewController, animated: Bool = true) {
        guard let superView = parent.view else { return }
        for sub in superView.subviews {
            guard let banner = sub as? PMBanner else { continue }
            banner.dismiss(animated: animated)
        }
    }
}

extension PMBanner {

    /// Setup dismiss timer for `PMBanner`
    /// - Parameter duration: `PMBanner` will dismiss after `duration` seconds, `Double.infinity` means never dismiss automatically
    private func setupDismissTimer(duration: TimeInterval) {
        self.invalidateTimer()
        guard duration != Double.infinity else { return }
        self.timer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false, block: { [weak self](_) in
            self?.dismiss()
        })
    }

    /// Cancel dismiss timer
    private func invalidateTimer() {
        self.timer?.invalidate()
        self.timer = nil
    }

    /// Subscribe keyboard notification
    private func subscribeNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    private func unsubscribeNotification() {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: UI Relative
extension PMBanner {
    /// Setup elements of `PMBanner` by initializing data
    private func setupElements() {
        let imgView = self.setup(icon)
        let iconBtn = self.setup(iconButton, handler: iconButtonHandler)
        let textBtn = self.setup(textButton, handler: textButtonHandler)
        let textView = self.createMessage(message: message, attributedString: attributedString)
        self.textView = textView
        self.setupConstraintFor(textView, by: imgView, iconBtn, textBtn)
    }

    /// Initialize icon of `PMBanner` which is on top-left and its constraints
    private func setup(_ icon: UIImage?) -> UIImageView? {
        guard let _icon = icon else { return nil }

        let imgView = UIImageView(image: _icon)
        imgView.backgroundColor = self.style.bannerIconBgColor
        imgView.tintColor = self.style.bannerIconColor
        self.addSubview(imgView)
        imgView.setSizeContraint(height: ICON_SIZE, width: ICON_SIZE)
        NSLayoutConstraint.activate([
            imgView.topAnchor.constraint(equalTo: self.topAnchor, constant: BORDER_PADDING),
            imgView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: BORDER_PADDING)
        ])
        return imgView
    }

    /// Initialize icon button of `PMBanner` which is on top-right and its constraints
    private func setup(_ iconButton: UIImage?, handler: ((PMBanner) -> Void)?) -> UIButton? {
        guard let icon = iconButton else {
            return nil
        }
        self.iconButtonHandler = handler
        let btn = UIButton()
        btn.setImage(icon, for: .normal)
        btn.backgroundColor = self.style.assistBgColor
        btn.tintColor = self.style.assistTextColor
        btn.roundCorner(ICON_SIZE / 2)
        btn.setSizeContraint(height: ICON_SIZE, width: ICON_SIZE)
        self.addSubview(btn)
        NSLayoutConstraint.activate([
            btn.topAnchor.constraint(equalTo: self.topAnchor, constant: BORDER_PADDING),
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -1 * BORDER_PADDING)
        ])

        btn.addTarget(self, action: #selector(self.clickIconButton), for: .touchUpInside)
        return btn
    }

    /// Initialize text button of `PMBanner` which is on bottom-right and its constraints
    private func setup(_ textButton: String?, handler: ((PMBanner) -> Void)?) -> UIButton? {

        guard let text = textButton else {
            return nil
        }

        self.textButtonHandler = handler
        let btn = UIButton()
        btn.setTitle(text, for: .normal)
        btn.setBackgroundColor(self.style.assistBgColor, forState: .normal)
        btn.setBackgroundColor(self.style.assistHighBgColor, forState: .highlighted)
        btn.setTitleColor(self.style.assistTextColor, for: .normal)
        btn.titleLabel?.font = style.buttonFont
        btn.roundCorner(8)
        btn.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(btn)
        var buttonYPosConstraint: NSLayoutConstraint
        switch style.buttonVAlignment {
        case .center:
            buttonYPosConstraint = btn.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        case .bottom:
            buttonYPosConstraint = btn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * BORDER_PADDING)
        }
        NSLayoutConstraint.activate([
            buttonYPosConstraint,
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -style.buttonRightOffset)
        ])
        if let insets = style.buttonInsets {
            btn.contentEdgeInsets = insets
        } else {
            NSLayoutConstraint.activate([
                btn.heightAnchor.constraint(equalToConstant: ICON_SIZE),
                btn.widthAnchor.constraint(greaterThanOrEqualToConstant: 80)
            ])
        }
        btn.setContentCompressionResistancePriority(.init(1000), for: .horizontal)
        btn.addTarget(self, action: #selector(self.clickTextButton), for: .touchUpInside)
        return btn
    }

    /// Add pan gesture of `PMBanner`
    private func setupPanGesture() {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(self.bannerPan))

        self.addGestureRecognizer(pan)
    }

    /// Create message textView
    private func createMessage(message: String?, attributedString: NSAttributedString?) -> UITextView {

        let textView = UITextView()
        textView.isScrollEnabled = false
        textView.isEditable = false
        textView.delegate = self
        textView.backgroundColor = .clear
        textView.font = style.messageFont
        textView.textColor = self.style.bannerTextColor
        if let _link = self.linkAttributed {
            textView.linkTextAttributes = _link
        }
        if let message = message {
            textView.text = message
        }

        if let attributed = attributedString {
            textView.attributedText = attributed
        }
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textView)
        return textView
    }

    /// Setup constraints of message textView
    private func setupConstraintFor(_ textView: UITextView, by iconView: UIImageView?, _ iconBtn: UIButton?, _ textBtn: UIButton?) {

        let leftRef = iconView?.trailingAnchor ?? self.leadingAnchor
        let rightRef = textBtn?.leadingAnchor ?? iconBtn?.leadingAnchor ?? self.trailingAnchor

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: self.topAnchor, constant: style.borderInsets.top),
            textView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * style.borderInsets.bottom),
            textView.leadingAnchor.constraint(equalTo: leftRef, constant: style.borderInsets.left),
            textView.trailingAnchor.constraint(equalTo: rightRef, constant: -style.borderInsets.right).prioritised(as: .defaultLow.lower),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: ICON_SIZE)
        ])
        updateTextViewConstraints(textView)
        textView.setContentCompressionResistancePriority(.defaultLow.lower.lower.lower, for: .horizontal)
    }

    private func updateTextViewConstraints(_ textView: UITextView) {
        if traitCollection.horizontalSizeClass == .compact {
            textView.setContentHuggingPriority(.defaultLow.lower.lower.lower, for: .horizontal)
        } else {
            textView.setContentHuggingPriority(.required, for: .horizontal)
        }
    }

    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard traitCollection.horizontalSizeClass != previousTraitCollection?.horizontalSizeClass,
              let textView = textView
        else { return }
        updateTextViewConstraints(textView)
    }

    /// Setup constraints of `PMBanner`
    private func setupBannerConstraint(position: PMBannerPosition, parent: UIView) {
        self.translatesAutoresizingMaskIntoConstraints = false
        let insets = position.edgeInsets

        let left = self.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: insets.left)
        left.priority = UILayoutPriority.defaultLow.lower.lower
        left.isActive = true

        let right = self.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -1 * insets.right)
        right.priority = UILayoutPriority.defaultLow.lower.lower
        right.isActive = true

        self.centerXInSuperview()
        self.widthAnchor.constraint(lessThanOrEqualTo: parent.readableContentGuide.widthAnchor).isActive = true
        self.heightAnchor.constraint(greaterThanOrEqualToConstant: ICON_SIZE + 2 * style.borderInsets.top).isActive = true
        self.layoutIfNeeded()

        let initValue = self.calcBannerHeight()
        switch position {
        case .top, .topCustom:
            self.topConstraint = self.topAnchor.constraint(equalTo: parent.topAnchor, constant: -1 * initValue)
            self.topConstraint?.isActive = true
        case .bottom, .bottomCustom:
            self.bottomConstraint = self.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: initValue)
            self.bottomConstraint?.isActive = true
        }

    }

    private func calcBannerHeight() -> CGFloat {
        guard let textView = self.subviews.first(where: { $0 is UITextView }) else {
            return 0
        }
        let height = textView.bounds.height
        return height + 2 * style.borderInsets.top
    }

    private func showAnimate(ignoreKeyboard: Bool) {
        let keyboardHeight = ignoreKeyboard ? 0: self.getKeyboardHeight()
        guard let parent = self.superview else { return }
        switch self.position! {
        case .top, .topCustom:
            self.topConstraint?.constant = self.position!.edgeInsets.top + parent.safeGuide.top
        case .bottom, .bottomCustom:
            let height = keyboardHeight > 0 ? keyboardHeight: parent.safeGuide.bottom
            self.bottomConstraint?.constant = -1 * self.position!.edgeInsets.bottom - height
        }
        UIView.animate(withDuration: ANIMATE_DURATION) {
            self.superview?.layoutIfNeeded()
        }
    }

    private func dismissAnimate() {
        let height = self.frame.size.height
        switch self.position! {
        case .top, .topCustom:
            self.topConstraint?.constant = -1 * height
        case .bottom, .bottomCustom:
            self.bottomConstraint?.constant = height
        }
        UIView.animate(withDuration: self.ANIMATE_DURATION, animations: {
            self.superview?.layoutIfNeeded()
        }, completion: { (_) in
            self.removeFromSuperview()
        })
    }

    private func handlePanGesChanged(ges: UIPanGestureRecognizer) {
        // negative means pan up, otherwise pan down
        let yVelocity = ges.velocity(in: self).y

        switch self.position! {
        case .top, .topCustom:
            if yVelocity <= -500 {
                self.dismissAnimate()
                ges.cancel()
                return
            }
            let translation = ges.translation(in: self)
            let newY = min(self.initLocation.y + 30,
                           self.lastLocation.y + translation.y)
            self.center = CGPoint(x: self.lastLocation.x,
                                  y: newY)
        case .bottom, .bottomCustom:
            if yVelocity >= 500 {
                self.dismissAnimate()
                ges.cancel()
                return
            }
            let translation = ges.translation(in: self)
            let newY = max(self.initLocation.y - 30,
                           self.lastLocation.y + translation.y)
            self.center = CGPoint(x: self.lastLocation.x,
                                  y: newY)
        }
    }
}

// MARK: Action
extension PMBanner {
    @objc private func clickIconButton() {
        self.iconButtonHandler?(self)
    }

    @objc private func clickTextButton() {
        self.textButtonHandler?(self)
    }

    @objc private func bannerPan(ges: UIPanGestureRecognizer) {
        if style.lockSwipeWhenButton, textButton != nil { return }
        switch ges.state {
        case .began:
            self.invalidateTimer()
            self.initLocation = self.center
            self.lastLocation = self.center
        case .changed:
            self.handlePanGesChanged(ges: ges)
        case .ended:
            self.dismissAnimate()
        default:
            break
        }
    }

    @objc private func keyboardWillShow(noti: Notification) {

        guard let info = noti.userInfo,
              let frame = info["UIKeyboardFrameEndUserInfoKey"] as? CGRect else {
            return
        }
        let height = frame.size.height
        if case .bottom = self.position! {
            self.bottomConstraint?.constant = -1 * self.position!.edgeInsets.bottom - height
            UIView.animate(withDuration: ANIMATE_DURATION) {
                self.superview?.layoutIfNeeded()
            }
        }
    }

    @objc private func keyboardWillHide(noti: Notification) {
        guard let parent = self.superview else { return }

        if case .bottom = self.position! {
            self.bottomConstraint?.constant = -1 * self.position!.edgeInsets.bottom - parent.safeGuide.bottom
            UIView.animate(withDuration: ANIMATE_DURATION) {
                self.superview?.layoutIfNeeded()
            }
        }
    }
}

extension PMBanner: UITextViewDelegate {
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if let _handler = self.linkHandler {
            _handler(self, URL)
        }
        return false
    }
}
