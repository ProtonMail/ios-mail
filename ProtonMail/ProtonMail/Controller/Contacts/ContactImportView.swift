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

final class ContactImportView: UIView {
    private let backgroundImageView = SubviewFactory.backgroundImageView
    let contentView = SubviewFactory.contentView
    private let logoView = SubviewFactory.logoView
    let titleLabel = SubviewFactory.titleLabel
    let progressView = SubviewFactory.progressView
    let messageLabel = SubviewFactory.messageLabel
    let cancelButton = SubviewFactory.cancelButton

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupLayout()
    }

    private func addSubviews() {
        addSubview(backgroundImageView)
        addSubview(contentView)
        contentView.addSubview(logoView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(progressView)
        contentView.addSubview(messageLabel)
        contentView.addSubview(cancelButton)
    }

    private func setupLayout() {
        backgroundImageView.fillSuperview()

        [
            contentView.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentView.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentView.widthAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 1.174)
        ].activate()

        let leading = contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20)
        leading.priority = .defaultLow
        leading.isActive = true
        let trailing = contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        trailing.priority = .defaultLow
        trailing.isActive = true

        let height = contentView.heightAnchor.constraint(lessThanOrEqualToConstant: 400)
        height.priority = .defaultLow
        height.isActive = true

        [
            logoView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            logoView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 24),
            logoView.heightAnchor.constraint(equalToConstant: 72),
            logoView.widthAnchor.constraint(equalToConstant: 72)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: logoView.bottomAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.heightAnchor.constraint(equalToConstant: 28)
        ].activate()

        [
            progressView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            progressView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
            progressView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
            progressView.heightAnchor.constraint(equalToConstant: 8)
        ].activate()
        progressView.setContentHuggingPriority(.defaultHigh, for: .vertical)

        [
            messageLabel.topAnchor.constraint(equalTo: progressView.bottomAnchor, constant: 12),
            messageLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            messageLabel.heightAnchor.constraint(equalToConstant: 32)
        ].activate()
        messageLabel.setContentHuggingPriority(.required, for: .vertical)

        [
            cancelButton.topAnchor.constraint(equalTo: messageLabel.bottomAnchor, constant: 24),
            cancelButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cancelButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cancelButton.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            cancelButton.heightAnchor.constraint(equalToConstant: 48)
        ].activate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private enum SubviewFactory {
    static var backgroundImageView: UIImageView {
        let imageView = UIImageView(image: Asset.popupBehindImage.image)
        imageView.contentMode = .scaleToFill
        return imageView
    }

    static var contentView: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.layer.cornerRadius = 8.0
        return view
    }

    static var logoView: UIImageView {
        let imageView = UIImageView(image: IconProvider.mailMain)
        imageView.layer.cornerRadius = 16
        imageView.layer.borderColor = ColorProvider.SeparatorNorm.cgColor
        imageView.layer.borderWidth = 1
        imageView.contentMode = .scaleAspectFit
        return imageView
    }

    static var titleLabel: UILabel {
        let title = "".apply(style: .Headline.alignment(.center))
        let label = UILabel(attributedString: title)
        return label
    }

    static var messageLabel: UILabel {
        let title = "".apply(style: .CaptionWeak.alignment(.center))
        let label = UILabel(attributedString: title)
        label.textColor = ColorProvider.TextWeak
        return label
    }

    static var progressView: UIProgressView {
        let view = UIProgressView(progressViewStyle: .default)
        view.progress = 0.33
        view.progressTintColor = ColorProvider.BrandNorm
        view.trackTintColor = ColorProvider.InteractionWeak
        return view
    }

    static var cancelButton: ProtonButton {
        let button = ProtonButton(frame: .zero)
        button.setMode(mode: .outlined)
        button.setTitle(LocalString._general_cancel_button, for: .normal)
        button.tintColor = ColorProvider.NotificationError
        button.setTitleColor(ColorProvider.NotificationError, for: .normal)
        button.setTitleColor(ColorProvider.NotificationError, for: .disabled)
        button.layer.borderColor = ColorProvider.NotificationError.cgColor
        return button
    }
}
