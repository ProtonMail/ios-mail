// Copyright (c) 2023 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import ProtonCoreFoundations
import ProtonCoreUIFoundations
import UIKit

final class ReferralPromptView: UIView, AccessibleView {
    private let containerView = SubviewFactory.containerView
    private let closeButton = SubviewFactory.closeButton
    private let imageContainer = SubviewFactory.imageContainer
    private let illustration = SubviewFactory.illustrationView
    private let enclosingView = SubviewFactory.enclosingView
    private let titleLabel = SubviewFactory.titleLabel
    private let contentLabel = SubviewFactory.contentLabel
    private let referButton = SubviewFactory.referButton
    private let laterButton = SubviewFactory.laterButton
    private var containerBottomConstraint: NSLayoutConstraint!

    private let onHandleRefer: ((ReferralPromptView) -> Void)

    init(onHandleRefer: @escaping ((ReferralPromptView) -> Void)) {
        self.onHandleRefer = onHandleRefer
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = ColorProvider.BlenderNorm.withAlphaComponent(0.46)
        generateAccessibilityIdentifiers()
        addSubviews()
        setupLayout()
        setupFont()
        setupFunction()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(on view: UIView) {
        view.addSubview(self)
        self.fillSuperview()
        containerBottomConstraint.constant = view.frame.height
        view.layoutIfNeeded()

        self.containerBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    @objc
    func dismiss() {
        self.containerBottomConstraint.constant = self.frame.height
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.removeFromSuperview()
            }
        )
    }

    @objc
    private func handleRefer() {
        onHandleRefer(self)
    }

    private func addSubviews() {
        addSubview(containerView)
        containerView.addSubview(imageContainer)
        imageContainer.addSubview(illustration)
        containerView.addSubview(closeButton)
        containerView.addSubview(enclosingView)
        enclosingView.addSubview(titleLabel)
        enclosingView.addSubview(contentLabel)
        enclosingView.addSubview(referButton)
        enclosingView.addSubview(laterButton)
    }

    private func setupLayout() {
        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        containerBottomConstraint = bottomConstraint
        [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerBottomConstraint
        ].activate()
        [
            imageContainer.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: 0.576)
        ].activate()
        illustration.fillSuperview()

        let topMargin: CGFloat = 32
        let verticalMargin: CGFloat = 16
        let horizontalMargin: CGFloat = 24
        let verticalMinSize: CGFloat = 48
        let bottomMargin: CGFloat = 48

        [
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontalMargin),
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: topMargin),

            enclosingView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: topMargin),
            enclosingView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: horizontalMargin),
            enclosingView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -horizontalMargin),
            enclosingView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -bottomMargin),

            titleLabel.topAnchor.constraint(equalTo: enclosingView.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: enclosingView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: enclosingView.trailingAnchor),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: verticalMargin),
            contentLabel.leadingAnchor.constraint(equalTo: enclosingView.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: enclosingView.trailingAnchor),

            referButton.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: verticalMargin),
            referButton.leadingAnchor.constraint(equalTo: enclosingView.leadingAnchor),
            referButton.trailingAnchor.constraint(equalTo: enclosingView.trailingAnchor),
            referButton.heightAnchor.constraint(equalToConstant: verticalMinSize),

            laterButton.topAnchor.constraint(equalTo: referButton.bottomAnchor, constant: verticalMargin),
            laterButton.leadingAnchor.constraint(equalTo: enclosingView.leadingAnchor),
            laterButton.trailingAnchor.constraint(equalTo: enclosingView.trailingAnchor),
            laterButton.heightAnchor.constraint(equalToConstant: verticalMinSize),
            laterButton.bottomAnchor.constraint(equalTo: enclosingView.bottomAnchor)
        ].activate()
    }

    private func setupFont() {
        titleLabel.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        contentLabel.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        referButton.layoutIfNeeded()
        laterButton.layoutIfNeeded()
    }

    private func setupFunction() {
        closeButton.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        referButton.addTarget(self, action: #selector(self.handleRefer), for: .touchUpInside)
        laterButton.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        gesture.delegate = self
        addGestureRecognizer(gesture)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupFont()
    }
}

extension ReferralPromptView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            // Check user tap position is gray overlay or container view
            let point = gestureRecognizer.location(in: containerView)
            // tap gray overlay
            if point.y < 0 {
                return true
            }
        }
        return false
    }
}

private enum SubviewFactory {
    static var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.roundCorner(8.0)
        return view
    }()

    static var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(IconProvider.cross, for: .normal)
        button.tintColor = ColorProvider.BlenderNorm
        return button
    }()

    static var imageContainer: UIView {
        let view = UIView()
        return view
    }

    static var illustrationView: UIImageView {
        let image = UIImageView(image: Asset.referralLogo.image)
        image.contentMode = .scaleAspectFit
        return image
    }

    static var enclosingView: UIView {
        UIView()
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.text = L10n.ReferralProgram.title
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        label.text = L10n.ReferralProgram.promptContent
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var referButton: ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .solid)
        button.setTitle(L10n.ReferralProgram.referAFriend, for: .normal)
        return button
    }

    static var laterButton: ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .text)
        button.setTitle(L10n.ReferralProgram.maybeLater, for: .normal)
        return button
    }
}
