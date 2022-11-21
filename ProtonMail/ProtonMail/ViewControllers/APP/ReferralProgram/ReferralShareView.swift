// Copyright (c) 2022 Proton Technologies AG
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

import ProtonCore_UIFoundations
import UIKit

final class ReferralShareView: UIView {
    private let scrollView = UIScrollView(frame: .zero)
    private let scrollContainer = UIView(frame: .zero)

    private let imageContainer = SubviewFactory.imageContainer
    private let illustration = SubviewFactory.illustrationView
    private let contentStackView = SubviewFactory.contentStackView
    private let titleLabel = SubviewFactory.titleLabel
    private let contentLabel = SubviewFactory.contentLabel
    private let inviteLinkLabel = SubviewFactory.inviteLinkLabel
    let linkTextField = SubviewFactory.linkTextField
    let linkShareButton = SubviewFactory.linkShareButton
    let shareButton = SubviewFactory.shareButton
    let trackRewardButton = SubviewFactory.trackRewardButton
    let termsAndConditionButton = SubviewFactory.bottomButton

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        addSubviews()
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubviews() {
        addSubview(scrollView)
        scrollView.addSubview(scrollContainer)

        scrollContainer.addSubview(imageContainer)
        imageContainer.addSubview(illustration)
        scrollContainer.addSubview(contentStackView)
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(contentLabel)
        contentStackView.addArrangedSubview(inviteLinkLabel)
        contentStackView.addArrangedSubview(linkTextField)
        contentStackView.addArrangedSubview(shareButton)
        linkTextField.delegate = self

        scrollContainer.addSubview(trackRewardButton)
        scrollContainer.addSubview(termsAndConditionButton)
    }

    private func setupLayout() {
        [
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor),
            scrollContainer.widthAnchor.constraint(equalTo: widthAnchor),
            scrollContainer.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.heightAnchor, multiplier: 1)
        ].activate()
        scrollContainer.fillSuperview()
        [
            imageContainer.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor),
            imageContainer.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor),
            imageContainer.topAnchor.constraint(equalTo: scrollContainer.topAnchor),
            imageContainer.heightAnchor.constraint(equalTo: imageContainer.widthAnchor, multiplier: 0.576)
        ].activate()
        illustration.fillSuperview()
        contentLabel.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        [
            contentStackView.topAnchor.constraint(equalTo: imageContainer.bottomAnchor, constant: 32),
            contentStackView.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor, constant: 24),
            contentStackView.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor, constant: -24),
            linkTextField.heightAnchor.constraint(equalToConstant: 48),
            shareButton.heightAnchor.constraint(equalToConstant: 48),
            contentStackView.bottomAnchor.constraint(lessThanOrEqualTo: trackRewardButton.topAnchor, constant: -16)
        ].activate()

        [
            termsAndConditionButton.bottomAnchor.constraint(equalTo: scrollContainer.bottomAnchor),
            termsAndConditionButton.trailingAnchor.constraint(equalTo: scrollContainer.trailingAnchor),
            termsAndConditionButton.leadingAnchor.constraint(equalTo: scrollContainer.leadingAnchor),
            termsAndConditionButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 20)
        ].activate()
        [
            trackRewardButton.trailingAnchor.constraint(equalTo: contentStackView.trailingAnchor),
            trackRewardButton.leadingAnchor.constraint(equalTo: contentStackView.leadingAnchor),
            trackRewardButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            trackRewardButton.bottomAnchor.constraint(equalTo: termsAndConditionButton.topAnchor, constant: -24)
        ].activate()
    }

    func setupFont() {
        titleLabel.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        contentLabel.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        inviteLinkLabel.font = UIFont.adjustedFont(forTextStyle: .footnote, weight: .semibold)
        shareButton.layoutIfNeeded()
        trackRewardButton.titleLabel?.font = UIFont.adjustedFont(forTextStyle: .body)

        var attributes = FontManager.DefaultSmall + [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: ColorProvider.TextNorm as UIColor,
            .font: UIFont.adjustedFont(forTextStyle: .subheadline)
        ]
        attributes = attributes.alignment(.center)
        termsAndConditionButton.setAttributedTitle(
            L11n.ReferralProgram.termsAndConditionTitle
                .apply(style: attributes),
            for: .normal)
    }
}

extension ReferralShareView: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return false
    }
}

private enum SubviewFactory {
    static var imageContainer: UIView {
        let view = UIView()
        return view
    }

    static var illustrationView: UIImageView {
        let image = UIImageView(image: Asset.referralLogo.image)
        image.contentMode = .scaleAspectFit
        return image
    }

    static var contentStackView: UIStackView {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 16.0
        return stackView
    }

    static var titleLabel: UILabel {
        let label = UILabel()
        label.font = UIFont.adjustedFont(forTextStyle: .title2, weight: .bold)
        label.lineBreakMode = .byWordWrapping
        label.textAlignment = .center
        label.text = L11n.ReferralProgram.title
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var contentLabel: UILabel {
        let label = UILabel()
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.adjustedFont(forTextStyle: .subheadline)
        label.text = L11n.ReferralProgram.content
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static var inviteLinkLabel: UILabel {
        let label = UILabel()
        label.font = UIFont.adjustedFont(forTextStyle: .footnote, weight: .semibold)
        label.text = L11n.ReferralProgram.inviteLinkTitle
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        return label
    }

    static let linkShareButton: UIButton = {
        let imageButton = UIButton(image: IconProvider.squares)
        imageButton.contentMode = .scaleAspectFit
        imageButton.tintColor = ColorProvider.IconWeak
        return imageButton
    }()

    static var linkTextField: UITextField {
        let textField = TextFieldWithPadding(frame: .zero)
        textField.backgroundColor = ColorProvider.BackgroundSecondary
        textField.roundCorner(8)
        textField.rightViewMode = .always
        textField.textColor = ColorProvider.TextWeak

        let buttonContainer = UIView(frame: .init(x: 0, y: 0, width: 48, height: 48))
        let imageButton = SubviewFactory.linkShareButton
        buttonContainer.addSubview(imageButton)
        imageButton.frame = .init(x: 0, y: 0, width: 24, height: 24)
        imageButton.center = buttonContainer.center

        textField.rightView = buttonContainer
        return textField
    }

    static var shareButton: ProtonButton {
        let button = ProtonButton()
        button.setMode(mode: .solid)
        button.setTitle(L11n.ReferralProgram.shareTitle, for: .normal)
        return button
    }

    static var trackRewardButton: UIButton {
        let button = ButtonWithImageOnTheRight()
        button.setTitle(L11n.ReferralProgram.trackRewardTitle, for: .normal)
        button.titleLabel?.font = UIFont.adjustedFont(forTextStyle: .body)
        button.titleLabel?.textAlignment = .center
        button.setTitleColor(ColorProvider.TextWeak, for: .normal)
        button.layer.borderColor = ColorProvider.IconWeak.cgColor
        button.layer.borderWidth = 1
        button.roundCorner(8)
        button.backgroundColor = .clear
        button.setImage(IconProvider.arrowOutSquare, for: .normal)
        button.imageView?.tintColor = ColorProvider.IconWeak
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        return button
    }

    static var bottomButton: UIButton {
        let label = UIButton()
        var attributes = FontManager.DefaultSmall + [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: ColorProvider.TextNorm as UIColor,
            .font: UIFont.adjustedFont(forTextStyle: .subheadline)
        ]
        attributes = attributes.alignment(.center)
        label.setAttributedTitle(
            L11n.ReferralProgram.termsAndConditionTitle
                .apply(style: attributes),
            for: .normal)
        label.titleLabel?.adjustsFontForContentSizeCategory = true
        return label
    }
}

private class ButtonWithImageOnTheRight: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        if let imageView = imageView {
            imageEdgeInsets = UIEdgeInsets(
                top: 5,
                left: bounds.width - 35,
                bottom: 5,
                right: 5
            )
            titleEdgeInsets = UIEdgeInsets(
                top: 0,
                left: 0,
                bottom: 0,
                right: imageView.frame.width
            )
        }
    }
}

private class TextFieldWithPadding: UITextField {
    var textPadding = UIEdgeInsets(
        top: 10,
        left: 16,
        bottom: 10,
        right: 16
    )

    override func textRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.textRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        let rect = super.editingRect(forBounds: bounds)
        return rect.inset(by: textPadding)
    }
}
