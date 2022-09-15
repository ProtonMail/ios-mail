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
        // TODO: switch to use color from Core
        backgroundColor = UIColor(hexColorCode: "#239ECE")
        roundCorner(8)
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
        infoLabel.text = String(format: LocalString._edit_scheduled_button_message,
                                date,
                                time)
        infoLabel.textAlignment = .left
        infoLabel.font = UIFont.systemFont(ofSize: 13)
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
        button.setTitle(LocalString._edit_scheduled_button_title, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.white.cgColor
        button.layer.cornerRadius = 8
        button.setCornerRadius(radius: 8)
        return button
    }

    static var iconImageView: UIImageView {
        let imageView = UIImageView(image: IconProvider.clock)
        imageView.tintColor = UIColor.white
        return imageView
    }

    static var infoLabel: UILabel {
        let label = UILabel()
        label.textColor = UIColor.white
        label.numberOfLines = 0
        return label
    }

}
