// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import ProtonCore_UIFoundations
import UIKit

final class ConversationViewNoticeView: UIView {
    private let backgroundView = SubviewsFactory.backgroundView
    private let contentView = SubviewsFactory.contentView
    private var contentViewHeightConstraint: NSLayoutConstraint?
    private var contentBottomConstraint: NSLayoutConstraint?
    private let heightRatio: CGFloat = 356 / 812
    private let maxWidth: CGFloat = 414.0
    private let upperView = SubviewsFactory.upperView
    private let dismissButton = SubviewsFactory.dismissButton
    private let imageView = SubviewsFactory.imageView
    private let titleLabel = SubviewsFactory.titleLabel
    private let messageLabel = SubviewsFactory.messageLabel
    private let actionButton = SubviewsFactory.actionButton
    private var goToSettingClosure: (() -> Void)?

    init() {
        super.init(frame: .zero)
        addSubViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        contentView.roundCorners([.topLeft, .topRight], radius: 8)
    }

    private func addSubViews() {
        addSubview(backgroundView)
        addSubview(contentView)
        contentView.addSubview(upperView)
        upperView.addSubview(imageView)
        upperView.addSubview(dismissButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(messageLabel)
        contentView.addSubview(actionButton)
    }

    private func setupLayout() {
        [
            backgroundView.topAnchor.constraint(equalTo: topAnchor),
            backgroundView.bottomAnchor.constraint(equalTo: bottomAnchor),
            backgroundView.leadingAnchor.constraint(equalTo: leadingAnchor),
            backgroundView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()

        let heightConstraint = contentView.heightAnchor.constraint(equalToConstant: 100)
        self.contentViewHeightConstraint = heightConstraint
        let bottomConstraint = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        self.contentBottomConstraint = bottomConstraint
        [
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor)
                .setPriority(as: .init(rawValue: 999)),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor)
                .setPriority(as: .init(rawValue: 999)),
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomConstraint,
            heightConstraint,
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth)
        ].activate()

        setupUpperViewLayout()

        [
            titleLabel.topAnchor.constraint(equalTo: upperView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ].activate()

        [
            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ].activate()

        [
            actionButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 16),
            actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            actionButton.heightAnchor.constraint(equalToConstant: 48)
        ].activate()
        actionButton.addTarget(self,
                               action: #selector(self.goToSetting),
                               for: .touchUpInside)
    }

    private func setupUpperViewLayout() {
        [
            upperView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            upperView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            upperView.topAnchor.constraint(equalTo: contentView.topAnchor),
            upperView.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 160 / 356)
        ].activate()

        [
            dismissButton.widthAnchor.constraint(equalToConstant: 40),
            dismissButton.heightAnchor.constraint(equalToConstant: 40),
            dismissButton.topAnchor.constraint(equalTo: upperView.topAnchor, constant: 16),
            dismissButton.leadingAnchor.constraint(equalTo: upperView.leadingAnchor, constant: 8)
        ].activate()
        dismissButton.addTarget(self,
                                action: #selector(self.dismiss),
                                for: .touchUpInside)

        [
            imageView.topAnchor.constraint(equalTo: upperView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: upperView.bottomAnchor),
            imageView.leadingAnchor.constraint(equalTo: upperView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: upperView.trailingAnchor)
        ].activate()
    }

    func presentAt(_ parentVC: UIViewController,
                   animated: Bool,
                   goToSetting: @escaping () -> Void) {
        guard let parentView = parentVC.view else { return }
        self.goToSettingClosure = goToSetting
        parentView.addSubview(self)
        [
            self.topAnchor.constraint(equalTo: parentView.topAnchor),
            self.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            self.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: parentView.trailingAnchor)
        ].activate()

        let height = parentVC.view.frame.height * self.heightRatio
        self.contentViewHeightConstraint?.constant = height
        self.contentBottomConstraint?.constant = animated ? height : 0

        parentView.layoutIfNeeded()

        guard animated else { return }
        UIView.animate(withDuration: 0.25) {
            self.contentBottomConstraint?.constant = 0
            self.layoutIfNeeded()
        }

    }

    @objc
    private func dismiss() {
        UIView.animate(withDuration: 0.25,
                       animations: {
            self.contentBottomConstraint?.constant = self.contentViewHeightConstraint?.constant ?? 0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.removeFromSuperview()
        })
    }

    @objc
    private func goToSetting() {
        UIView.animate(withDuration: 0.25,
                       animations: {
            self.contentBottomConstraint?.constant = self.contentViewHeightConstraint?.constant ?? 0
            self.layoutIfNeeded()
        }, completion: { _ in
            self.removeFromSuperview()
            self.goToSettingClosure?()
        })
    }
}

private enum SubviewsFactory {
    static var backgroundView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BlenderNorm.withAlphaComponent(0.46)
        return view
    }

    static var contentView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    static var upperView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        return view
    }

    static var dismissButton: UIButton {
        let button = UIButton(image: Asset.actionSheetClose.image.toTemplateUIImage())
        button.imageView?.tintColor = ColorProvider.IconNorm
        return button
    }

    static var imageView: UIImageView {
        let view = UIImageView(image: Asset.conversationNotice.image)
        view.contentMode = .scaleAspectFit
        return view
    }

    static var titleLabel: UILabel {
        let title = LocalString._conversation_notice_title
        let label = UILabel(attributedString: title.apply(style: .DefaultStrong.alignment(.center)))
        return label
    }

    static var messageLabel: UILabel {
        let title = LocalString._conversation_notice_message
        let label = UILabel(attributedString: title.apply(style: .CaptionWeak.alignment(.center)))
        return label
    }

    static var actionButton: ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .solid)
        button.setTitle(LocalString._conversation_notice_action_title, for: .normal)
        return button
    }
}

private extension UIView {
    func roundCorners(_ corners: UIRectCorner, radius: CGFloat) {
        let path = UIBezierPath(roundedRect: self.bounds,
                                byRoundingCorners: corners,
                                cornerRadii: CGSize(width: radius, height: radius))
        let mask = CAShapeLayer()
        mask.path = path.cgPath
        self.layer.mask = mask
    }
}
