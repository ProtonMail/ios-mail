// Copyright (c) 2021 Proton Technologies AG
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

import UIKit
import ProtonCore_UIFoundations

final class DecryptionErrorBannerView: UIView {

    private let iconView = SubviewsFactory.iconImageView
    private let titleLabel = SubviewsFactory.titleLabel
    private let button = SubviewsFactory.button

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.NotificationError
        setCornerRadius(radius: 8)
        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(button)
    }

    private func setUpLayout() {
        [
            iconView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            iconView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 12.0),
            iconView.heightAnchor.constraint(equalToConstant: 20.0),
            iconView.widthAnchor.constraint(equalToConstant: 20.0)
        ].activate()

        [
            button.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            button.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                             constant: -12),
            button.heightAnchor.constraint(equalToConstant: 32)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -12),
            titleLabel.trailingAnchor.constraint(equalTo: button.leadingAnchor, constant: -8),
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 8)
        ].activate()
    }

    func setUpTryAgainAction(target: UIViewController, action: Selector) {
        self.button.addTarget(target, action: action, for: .touchUpInside)
    }
}

private enum SubviewsFactory {

    static var titleLabel: UILabel {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = ColorProvider.TextInverted
        label.numberOfLines = 0
        label.text = "\(LocalString._decryption_error): \(LocalString._decryption_of_this_message_failed)"
        label.setContentHuggingPriority(.fittingSizeLevel, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        return label
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.icExclamationTriangle.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconInverted
        return imageView
    }

    static var button: UIButton {
        let button = UIButton(frame: .zero)
        button.backgroundColor = .clear
        button.layer.borderWidth = 1
        button.layer.borderColor = ColorProvider.IconInverted.cgColor
        button.setTitle(" \(LocalString._general_try_again) ", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        button.roundCorner(8)
        return button
    }
}
