//
//  PMBanner.swift
//  ProtonCore-UIFoundations - Created on 31.08.20.
//
//  Copyright (c) 2022 Proton Technologies AG
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
import ProtonCore_Foundations

public class PMBanner: UIView, AccessibleView {

    // MARK: Constants
    private let ICON_SIZE: CGFloat = 32
    private let ANIMATE_DURATION: TimeInterval = 0.25
    private let HIGHLIGHTED_BUTTON_IMAGE_PADDING: CGFloat = 8.0

    // MARK: Private Variables
    public let message: String?
    private let attributedString: NSAttributedString?
    private let icon: UIImage?
    public let style: PMBannerStyleProtocol
    private var dismissDuration: TimeInterval
    private var bannerHandler: ((PMBanner) -> Void)?
    private var actionButton: UIButton?
    private var buttonText: String?
    private var buttonIcon: UIImage?
    public private(set) var buttonHandler: ((PMBanner) -> Void)?
    private var activityIndicator: UIActivityIndicatorView?
    private var textView: UITextView?
    private var linkAttributed: [NSAttributedString.Key: Any]?
    public var linkHandler: ((PMBanner, URL) -> Void)?
    private var position: PMBannerPosition?
    private var timer: Timer?
    private var topConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var initLocation: CGPoint = .zero
    private var lastLocation: CGPoint = .zero

    public let userInfo: [AnyHashable: Any]?

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Initialize `PMBanner`
    /// - Parameters:
    ///   - message: Banner message
    ///   - style: Banner style
    ///   - icon: Banner icon that show on top-left
    ///   - dismissDuration: Banner will dismiss after `dismissDuration` seconds, `Double.infinity` means never dismiss automatically
    public convenience init(message: String,
                            style: PMBannerStyleProtocol,
                            icon: UIImage? = nil,
                            dismissDuration: TimeInterval = 4,
                            userInfo: [AnyHashable: Any]? = nil,
                            bannerHandler: ((PMBanner) -> Void)? = nil) {
        self.init(style: style,
                  message: message,
                  dismissDuration: dismissDuration,
                  icon: icon,
                  userInfo: userInfo,
                  bannerHandler: bannerHandler)
    }

    /// Initialize `PMBanner`
    /// - Parameters:
    ///   - message: Banner message
    ///   - style: Banner style
    ///   - icon: Banner icon that show on top-left
    ///   - dismissDuration: Banner will dismiss after `dismissDuration` seconds, `Double.infinity` means never dismiss automatically
    public convenience init(message: NSAttributedString,
                            style: PMBannerStyleProtocol,
                            icon: UIImage? = nil,
                            dismissDuration: TimeInterval = 4,
                            userInfo: [AnyHashable: Any]? = nil,
                            bannerHandler: ((PMBanner) -> Void)? = nil) {
        self.init(style: style,
                  message: nil,
                  dismissDuration: dismissDuration,
                  attributedString: message,
                  icon: icon,
                  userInfo: userInfo,
                  bannerHandler: bannerHandler)
    }

    private init(style: PMBannerStyleProtocol,
                 message: String?,
                 dismissDuration: TimeInterval = 4,
                 attributedString: NSAttributedString? = nil,
                 icon: UIImage? = nil,
                 userInfo: [AnyHashable: Any]?,
                 bannerHandler: ((PMBanner) -> Void)?) {
        self.style = style
        self.dismissDuration = dismissDuration
        self.message = message
        self.attributedString = attributedString
        self.icon = icon
        self.userInfo = userInfo
        super.init(frame: .zero)
        self.backgroundColor = style.bannerColor
        self.roundCorner(style.borderRadius)
        self.bannerHandler = bannerHandler
        self.setupTapGesture()
        self.setupPanGesture()
        generateAccessibilityIdentifiers()
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
        assert(self.buttonText == nil, "Only accept text button or icon button")
        self.buttonIcon = icon
        self.buttonHandler = handler
    }

    /// Add a text button on bottom-right
    /// - Parameters:
    ///   - icon: Icon of button
    ///   - handler: A block to execute when the user clicks the button.
    public func addButton(text: String, handler: ((PMBanner) -> Void)?) {
        assert(self.buttonIcon == nil, "Only accept text button or icon button")
        self.buttonText = text
        self.buttonHandler = handler
    }

    /// Show loading if there is a button on the right side
    public func setup(isLoading: Bool, dismissDuration: TimeInterval? = nil) {
        createActivityIndicator()
        guard let actionButton = self.actionButton,
              let activityIndicator = activityIndicator else { return }
        if isLoading {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
        if let duration = dismissDuration {
            self.dismissDuration = duration
            self.setupDismissTimer(duration: duration)
        }

        actionButton.isHidden = isLoading
        actionButton.isUserInteractionEnabled = !isLoading
    }

    /// Add appearance style and handler for link set by `NSAttributedString`
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

    public static func getBanners(in parent: UIViewController) -> [PMBanner] {
        guard let superView = parent.view else { return [] }
        return superView.subviews.compactMap { $0 as? PMBanner }
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
        subviews.forEach { $0.removeFromSuperview() }
        let imgView = self.setup(icon)
        if self.buttonText != nil && self.buttonIcon != nil {
            assert(false, "Only text or icon")
        }
        let iconBtn = self.setup(buttonIcon: buttonIcon)
        let textBtn = self.setup(buttonText: buttonText)
        self.actionButton = iconBtn ?? textBtn
        let textView = self.createMessage(message: message, attributedString: attributedString)
        self.textView = textView
        self.setupConstraintFor(textView, by: imgView, self.actionButton)
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
            imgView.topAnchor.constraint(equalTo: self.topAnchor,
                                         constant: style.borderInsets.top),
            imgView.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                             constant: style.borderInsets.left)
        ])
        return imgView
    }

    /// Initialize icon button of `PMBanner` which is on top-right and its constraints
    private func setup(buttonIcon: UIImage?) -> UIButton? {
        guard let icon = buttonIcon else { return nil }

        // normal button image
        let btn = UIButton()
        let imageView = createPaddingImageView(image: icon)
        imageView.tintColor = self.style.assistTextColor
        btn.setImage(imageView.asImage(), for: .normal)
        
        // highlighted button image
        let highlightedImageView = createPaddingImageView(image: icon)
        highlightedImageView.tintColor = self.style.assistTextColor
        highlightedImageView.backgroundColor = self.style.assistHighBgColor
        btn.setImage(highlightedImageView.asImage(), for: .highlighted)
        
        btn.tintColor = self.style.assistTextColor
        btn.roundCorner(ICON_SIZE / 2)
        btn.setSizeContraint(height: ICON_SIZE, width: ICON_SIZE)
        self.addSubview(btn)
        var buttonYPosConstraint: NSLayoutConstraint
        switch style.buttonVAlignment {
        case .center:
            buttonYPosConstraint = btn.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        case .bottom:
            buttonYPosConstraint = btn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * style.buttonMargin)
        }
        let constant = max(style.buttonMargin - (HIGHLIGHTED_BUTTON_IMAGE_PADDING / 2), 1)
        NSLayoutConstraint.activate([
            buttonYPosConstraint,
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -constant),
            btn.topAnchor.constraint(equalTo: self.topAnchor, constant: constant).prioritised(as: .defaultLow.lower),
            btn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -constant).prioritised(as: .defaultLow.lower)
        ])

        btn.addTarget(self, action: #selector(self.clickActionButton), for: .touchUpInside)
        return btn
    }
    
    private func createPaddingImageView(image: UIImage) -> UIImageView {
        let padding = HIGHLIGHTED_BUTTON_IMAGE_PADDING
        let img = image.imageWithInsets(insets: UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding))
        let imageView = UIImageView(image: img)
        imageView.layer.cornerRadius = imageView.bounds.size.width / 2
        return imageView
    }

    /// Initialize text button of `PMBanner` which is on bottom-right and its constraints
    private func setup(buttonText: String?) -> UIButton? {

        guard let text = buttonText else {
            return nil
        }

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
            buttonYPosConstraint = btn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * style.buttonMargin)
        }
        NSLayoutConstraint.activate([
            buttonYPosConstraint,
            btn.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -style.buttonMargin),
            btn.topAnchor.constraint(equalTo: self.topAnchor, constant: style.buttonMargin).prioritised(as: .defaultLow.lower),
            btn.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -1 * style.buttonMargin).prioritised(as: .defaultLow.lower)
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
        btn.addTarget(self, action: #selector(self.clickActionButton), for: .touchUpInside)
        return btn
    }

    /// Add tap gesture of `PMBanner`
    private func setupTapGesture() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.clickBanner))
        self.addGestureRecognizer(tap)
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
        textView.textContainerInset = .zero
        textView.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(textView)
        return textView
    }

    /// Setup constraints of message textView
    private func setupConstraintFor(_ textView: UITextView, by iconView: UIImageView?, _ actionButton: UIButton?) {

        let leftRef = iconView?.trailingAnchor ?? self.leadingAnchor
        let rightRef = actionButton?.leadingAnchor ?? self.trailingAnchor

        NSLayoutConstraint.activate([
            textView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            textView.topAnchor.constraint(greaterThanOrEqualTo: self.topAnchor, constant: style.borderInsets.top),
            textView.bottomAnchor.constraint(lessThanOrEqualTo: self.bottomAnchor, constant: -1 * style.borderInsets.bottom),
            textView.leadingAnchor.constraint(equalTo: leftRef, constant: style.borderInsets.left),
            textView.trailingAnchor.constraint(equalTo: rightRef, constant: -style.borderInsets.right).prioritised(as: .defaultLow.lower),
            textView.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
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
        setupElements()
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
        self.layoutIfNeeded()

        let initValue = self.frame.height
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

    private func createActivityIndicator() {
        if activityIndicator != nil { return }
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator?.color = self.style.assistTextColor
        } else {
            activityIndicator = UIActivityIndicatorView(style: .white)
        }
        guard let activityIndicator = activityIndicator,
              let actionButton = self.actionButton else { return }
        activityIndicator.hidesWhenStopped = true
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(activityIndicator)
        bringSubviewToFront(activityIndicator)

        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor)
        ])
        layoutIfNeeded()
    }
}

// MARK: Action
extension PMBanner {
    @objc private func clickBanner() {
        self.bannerHandler?(self)
    }

    @objc private func clickActionButton() {
        self.buttonHandler?(self)
    }

    @objc private func bannerPan(ges: UIPanGestureRecognizer) {
        if style.lockSwipeWhenButton, (buttonText != nil || buttonIcon != nil) { return }
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

    public func textViewDidChangeSelection(_ textView: UITextView) {
        textView.selectedTextRange = nil
    }
}
