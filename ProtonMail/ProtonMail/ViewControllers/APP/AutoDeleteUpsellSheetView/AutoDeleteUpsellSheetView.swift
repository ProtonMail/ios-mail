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

final class AutoDeleteUpsellSheetView: UIView, AccessibleView {
    private let containerView = SubviewFactory.containerView
    private let closeButton = SubviewFactory.closeButton
    private let illustration = SubviewFactory.illustrationView
    private let titleLabel = SubviewFactory.titleLabel
    private let contentLabel = SubviewFactory.contentLabel
    private let upgradeContainerView = SubviewFactory.upgradeContainerView
    private let upsellStackView = SubviewFactory.upsellStackView
    private let upgradeButton = SubviewFactory.upgradeButton
    private var containerBottomConstraint: NSLayoutConstraint!

    private let onHandleUpgrade: ((AutoDeleteUpsellSheetView) -> Void)

    init(onHandleUpgrade: @escaping ((AutoDeleteUpsellSheetView) -> Void)) {
        self.onHandleUpgrade = onHandleUpgrade
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
    private func handleUpgrade() {
        removeFromSuperview()
        onHandleUpgrade(self)
    }

    private func addSubviews() {
        addSubview(containerView)
        containerView.addSubview(illustration)
        containerView.addSubview(closeButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(upgradeContainerView)
        upgradeContainerView.addSubview(upsellStackView)
        upgradeContainerView.addSubview(upgradeButton)

        for position in SubviewFactory.UpsellLine.allCases {
            upsellStackView.addArrangedSubview(SubviewFactory.UpsellLineView(position: position))
        }
    }

    private func setupLayout() {
        let bottomConstraint = containerView.bottomAnchor.constraint(equalTo: bottomAnchor)
        containerBottomConstraint = bottomConstraint

        let margin: CGFloat = 16
        let buttonHeight: CGFloat = 48

        let illustrationHeightFactor = 0.25

        let iPadSpecificConstraints = [
            containerView.widthAnchor.constraint(equalToConstant: 375),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor)
        ]

        let iPhoneSpecificConstraint = [
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ]

        let remainingConstraints =
        [
            bottomConstraint,
            illustration.topAnchor.constraint(equalTo: containerView.topAnchor),
            illustration.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            illustration.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            illustration.heightAnchor.constraint(greaterThanOrEqualTo: containerView.heightAnchor,
                                                 multiplier: illustrationHeightFactor),

            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: margin),

            titleLabel.topAnchor.constraint(equalTo: illustration.bottomAnchor, constant: margin),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),

            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: margin),
            contentLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            contentLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),

            upgradeContainerView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: margin),
            upgradeContainerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: margin),
            upgradeContainerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -margin),
            upgradeContainerView.bottomAnchor.constraint(greaterThanOrEqualTo: containerView.bottomAnchor,
                                                         constant: -margin * 2).setPriority(as: .defaultLow),

            upsellStackView.leadingAnchor.constraint(equalTo: upgradeContainerView.leadingAnchor, constant: margin),
            upsellStackView.topAnchor.constraint(equalTo: upgradeContainerView.topAnchor, constant: margin),
            upsellStackView.trailingAnchor.constraint(equalTo: upgradeContainerView.trailingAnchor, constant: -margin),

            upgradeButton.topAnchor.constraint(equalTo: upsellStackView.bottomAnchor, constant: margin),
            upgradeButton.leadingAnchor.constraint(equalTo: upgradeContainerView.leadingAnchor, constant: margin),
            upgradeButton.trailingAnchor.constraint(equalTo: upgradeContainerView.trailingAnchor, constant: -margin),
            upgradeButton.bottomAnchor.constraint(equalTo: upgradeContainerView.bottomAnchor, constant: -margin),
            upgradeButton.heightAnchor.constraint(lessThanOrEqualToConstant: buttonHeight)
        ]

        if UIDevice.current.userInterfaceIdiom == .pad {
            iPadSpecificConstraints.appending(remainingConstraints).activate()
        } else {
            iPhoneSpecificConstraint.appending(remainingConstraints).activate()
        }
    }

    private func setupFont() {
        titleLabel.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        contentLabel.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        for case let view as SubviewFactory.UpsellLineView in upsellStackView.arrangedSubviews {
            view.label.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        }
        upgradeButton.layoutIfNeeded()
    }

    private func setupFunction() {
        closeButton.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        upgradeButton.addTarget(self, action: #selector(self.handleUpgrade), for: .touchUpInside)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        gesture.delegate = self
        addGestureRecognizer(gesture)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupFont()
    }
}

extension AutoDeleteUpsellSheetView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            // Check user tap position is gray overlay or container view
            let point = gestureRecognizer.location(in: containerView)
            // tap gray overlay
            if point.y < 0 || point.x < 0 || point.x > containerView.frame.width {
                return true
            }
        }
        return false
    }
}

private enum SubviewFactory {

    enum UpsellLine: CaseIterable {
        case one
        case two
        case three
        case four
    }

    final class UpsellLineView: UIView {
        let iconView: UIImageView
        let label: UILabel

        init(position: UpsellLine) {
            iconView = SubviewFactory.iconImageView(at: position)
            label = SubviewFactory.lineLabel(at: position)
            super.init(frame: .zero)
            addSubview(iconView)
            addSubview(label)
            setupLayout()
        }

        required init?(coder: NSCoder) {
            fatalError("Please use init(position: UpsellLine)")
        }

        private func setupLayout() {
            [
                iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
                iconView.topAnchor.constraint(equalTo: topAnchor),
                iconView.widthAnchor.constraint(equalToConstant: 16),
                iconView.bottomAnchor.constraint(equalTo: bottomAnchor).setPriority(as: .defaultLow),
                iconView.heightAnchor.constraint(equalTo: iconView.widthAnchor, multiplier: 1),
                label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 16),
                label.centerYAnchor.constraint(equalTo: iconView.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: trailingAnchor),
                label.bottomAnchor.constraint(equalTo: bottomAnchor).setPriority(as: .defaultLow)
            ].activate()
        }
    }

    static var containerView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.roundCorner(8.0)
        return view
    }

    static var closeButton: UIButton {
        let button = UIButton()
        button.setImage(IconProvider.cross, for: .normal)
        button.tintColor = ColorProvider.White
        return button
    }

    static var illustrationView: UIImageView {
        let image = UIImageView(image: Asset.upsellPromotion.image)
        image.contentMode = .scaleAspectFill
        return image
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.text = L10n.AutoDeleteUpsellSheet.title
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        label.textColor = ColorProvider.TextWeak
        label.text = L10n.AutoDeleteUpsellSheet.description
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var upgradeContainerView: UIView {
        let view = UIView()
        view.roundCorner(8.0)
        view.layer.borderColor = ColorProvider.InteractionNorm
        view.layer.borderWidth = 1
        return view
    }

    static var upsellStackView: UIStackView {
        let view = UIStackView()
        view.axis = .vertical
        view.spacing = 8
        view.distribution = .fillEqually
        return view
    }

    static func iconImageView(at position: UpsellLine) -> UIImageView {
        let icon: UIImage
        switch position {
        case .one:
            icon = IconProvider.storage
        case .two:
            icon = IconProvider.envelopes
        case .three:
            icon = IconProvider.folders
        case .four:
            icon = IconProvider.globe
        }
        let image = UIImageView(image: icon)
        image.tintColor = ColorProvider.InteractionNorm
        return image
    }

    static func lineLabel(at position: UpsellLine) -> UILabel {
        let label = UILabel()
        label.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        switch position {
        case .one:
            label.text = L10n.AutoDeleteUpsellSheet.upsellLineOne
        case .two:
            label.text = L10n.AutoDeleteUpsellSheet.upsellLineTwo
        case .three:
            label.text = L10n.PremiumPerks.unlimitedFoldersAndLabels
        case .four:
            label.text = L10n.AutoDeleteUpsellSheet.upsellLineFour
        }
        return label
    }

    static var upgradeButton: ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .solid)
        button.setTitle(L10n.AutoDeleteUpsellSheet.upgradeButtonTitle, for: .normal)
        return button
    }
}
