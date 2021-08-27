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

import ProtonCore_UIFoundations
import UIKit

final class ReceiptBannerView: UIView {
    let icon = SubviewsFactory.iconImageView
    let descLabel = SubviewsFactory.descLabel
    let sendButton = SubviewsFactory.sendButton
    let sentDescLabel = SubviewsFactory.sentDescLabel

    init() {
        super.init(frame: .zero)
        setUpSelf()
        addSubviews()
        setUpLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setUpSelf() {
        backgroundColor = UIColorManager.NotificationWarning
        roundCorner(8)
    }

    private func addSubviews() {
        addSubview(icon)
        addSubview(descLabel)
        addSubview(sendButton)
    }

    private func setUpLayout() {
        [
            icon.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                          constant: 16),
            icon.widthAnchor.constraint(equalToConstant: 20),
            icon.heightAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            descLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18),
            descLabel.centerYAnchor.constraint(equalTo: icon.centerYAnchor),
            descLabel.leadingAnchor.constraint(equalTo: icon.trailingAnchor,
                                               constant: 8),
            descLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                constant: -16)
        ].activate()

        [
            sendButton.topAnchor.constraint(equalTo: descLabel.bottomAnchor,
                                            constant: 14),
            sendButton.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                                constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                 constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 32),
            sendButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ].activate()
    }

    func hasSentReceipt() {
        sendButton.removeFromSuperview()
        addSubview(sentDescLabel)
        [
            sentDescLabel.topAnchor.constraint(equalTo: descLabel.bottomAnchor,
                                               constant: 14),
            sentDescLabel.leadingAnchor.constraint(equalTo: self.leadingAnchor,
                                                   constant: 16),
            sentDescLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor,
                                                    constant: -16),
            sentDescLabel.heightAnchor.constraint(equalToConstant: 32),
            sentDescLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16)
        ].activate()
    }
}

private enum SubviewsFactory {
    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: Asset.icBell.image)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = UIColorManager.IconNorm
        return imageView
    }

    static var descLabel: UILabel {
        let label = UILabel()
        let style = FontManager.Caption.lineBreakMode(.byWordWrapping)
        label.attributedText = LocalString._banner_requested_read_receipt.apply(style: style)
        label.setContentCompressionResistancePriority(.required, for: .vertical)
        label.numberOfLines = 0
        return label
    }

    static var sendButton: UIButton {
        let button = UIButton(frame: .zero)
        button.setAttributedTitle(LocalString._send_receipt.apply(style: FontManager.DefaultSmall), for: .normal)
        let color = UIColor(hexString: "#FFFFFF", alpha: 0.5)
        button.setBackgroundImage(.color(color), for: .normal)
        button.setCornerRadius(radius: 3)
        return button
    }

    static var sentDescLabel: UILabel {
        let label = UILabel()
        var style = FontManager.DefaultSmall.lineBreakMode()
        style.addTextAlignment(.center)
        label.attributedText = LocalString._receipt_sent.apply(style: style)
        label.backgroundColor = UIColor(hexString: "#FFFFFF", alpha: 0.5)
        label.setCornerRadius(radius: 3)
        return label
    }
}
