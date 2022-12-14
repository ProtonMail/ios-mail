//
//  UnsubscribeBanner.swift
//  ProtonMail
//
//
//  Copyright (c) 2021 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations
import UIKit

class EditScheduledBanner: UIView {

    private let infoLabel = SubviewsFactory.infoLabel
    private let editButton = SubviewsFactory.editButton
    private let iconImageView = SubviewsFactory.iconImageView
    private var editAction: (() -> Void)?

    init() {
        super.init(frame: .zero)
        setUpSelf()
        addSubviews()
        setUpLayout()
    }

    private func setUpSelf() {
        backgroundColor = ColorProvider.BackgroundNorm
        roundCorner(8)
        layer.borderColor = ColorProvider.SeparatorNorm
        layer.borderWidth = 1
    }

    private func addSubviews() {
        addSubview(infoLabel)
        addSubview(editButton)
        addSubview(iconImageView)
    }

    private func setUpLayout() {
        [
            iconImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconImageView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            iconImageView.heightAnchor.constraint(equalToConstant: 20),
            iconImageView.widthAnchor.constraint(equalToConstant: 20)
        ].activate()

        [
            infoLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            infoLabel.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 8),
            infoLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ].activate()

        [
            editButton.leadingAnchor.constraint(equalTo: infoLabel.trailingAnchor, constant: 16),
            editButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            editButton.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            editButton.topAnchor.constraint(equalTo: topAnchor, constant: 8)
        ].activate()
        editButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        editButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        editButton.addTarget(self,
                             action: #selector(self.handleEditAction),
                             for: .touchUpInside)
    }

    func configure(date: String, time: String, editAction: @escaping () -> Void) {
        let infoText = String(
            format: LocalString._edit_scheduled_button_message,
            date,
            time
        )
        infoLabel.set(text: infoText, preferredFont: .footnote, textColor: ColorProvider.TextNorm)
        self.editAction = editAction

        editButton.contentEdgeInsets = .init(top: 0, left: 10, bottom: 0, right: 10)
    }

    @objc
    private func handleEditAction() {
        editAction?()
    }

    required init?(coder: NSCoder) {
        nil
    }

}

private enum SubviewsFactory {

    static var editButton: UIButton {
        let button = UIButton(frame: .zero)
        button.titleLabel?.set(text: nil, preferredFont: .caption1)
        button.setTitle(LocalString._edit_scheduled_button_title, for: .normal)
        button.backgroundColor = ColorProvider.InteractionWeak
        button.setCornerRadius(radius: 8)
        button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        return button
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.clockPaperPlane)
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var infoLabel: UILabel {
        let label = UILabel()
        label.textColor = ColorProvider.TextNorm
        label.numberOfLines = 0
        return label
    }

}
