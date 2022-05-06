//
//  ConversationViewTrashedHintView.swift
//  Proton Mail
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import UIKit
import ProtonCore_UIFoundations

final class ConversationViewTrashedHintView: UIView {

    private let trashIcon = SubviewsFactory.trashIcon
    private let hintText = SubviewsFactory.hintText
    private let buttonContainer = SubviewsFactory.buttonContainer
    let button = SubviewsFactory.showButton

    required init?(coder: NSCoder) {
        nil
    }

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BackgroundNorm
        setCornerRadius(radius: 6)
        addSubviews()
        setUpLayout()
    }

    func setup(isTrashFolder: Bool, useShowButton: Bool) {
        let title = useShowButton ? LocalString._show: LocalString._hide
        button.setAttributedTitle(
            title.apply(style: FontManager.body2RegularNorm),
            for: .normal
        )
        if isTrashFolder {
            hintText.attributedText = LocalString._banner_non_trashed_message_title.apply(style: FontManager.Caption)
        } else {
            hintText.attributedText = LocalString._banner_trashed_message_title.apply(style: FontManager.Caption)
        }
        layoutIfNeeded()
    }

    private func addSubviews() {
        addSubview(trashIcon)
        addSubview(hintText)
        addSubview(buttonContainer)
        buttonContainer.addSubview(button)
    }

    private func setUpLayout() {
        [
            trashIcon.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 16),
            trashIcon.widthAnchor.constraint(equalToConstant: 20),
            trashIcon.heightAnchor.constraint(equalToConstant: 20),
            trashIcon.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ].activate()

        [
            buttonContainer.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -12),
            button.centerYAnchor.constraint(equalTo: self.centerYAnchor)
        ].activate()

        [
            button.topAnchor.constraint(equalTo: buttonContainer.topAnchor),
            button.leadingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: 12),
            button.trailingAnchor.constraint(equalTo: buttonContainer.trailingAnchor, constant: -12),
            button.bottomAnchor.constraint(equalTo: buttonContainer.bottomAnchor),
            button.widthAnchor.constraint(greaterThanOrEqualToConstant: 38),
            button.heightAnchor.constraint(equalToConstant: 36)
        ].activate()

        [
            hintText.leadingAnchor.constraint(equalTo: trashIcon.trailingAnchor, constant: 10),
            hintText.topAnchor.constraint(equalTo: self.topAnchor, constant: 14),
            hintText.trailingAnchor.constraint(equalTo: buttonContainer.leadingAnchor, constant: -28),
            hintText.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -14)
        ].activate()
    }
}

private enum SubviewsFactory {

    static var trashIcon: UIImageView {
        let imageView = UIImageView(image: IconProvider.trash)
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = ColorProvider.IconNorm
        return imageView
    }

    static var hintText: UILabel {
        let label = UILabel(frame: .zero)
        label.attributedText = LocalString._banner_trashed_message_title.apply(style: FontManager.Caption)
        label.numberOfLines = 0
        return label
    }

    static var showButton: UIButton {
        let button = UIButton(frame: .zero)
        button.setAttributedTitle(
            LocalString._show.apply(style: FontManager.body2RegularNorm),
            for: .normal
        )
        button.backgroundColor = .clear
        return button
    }

    static var buttonContainer: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.setCornerRadius(radius: 3)
        view.layer.borderColor = UIColor(hexString: "EAECF1", alpha: 1).cgColor
        view.layer.borderWidth = 1
        return view
    }
}
