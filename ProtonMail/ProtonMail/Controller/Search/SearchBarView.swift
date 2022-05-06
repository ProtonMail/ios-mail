//
//  SearchBarView.swift
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

import ProtonCore_UIFoundations
import UIKit

class SearchBarView: UIView {

    init() {
        super.init(frame: .zero)
        addSubviews()
        setUpLayout()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.layoutFittingExpandedSize.width, height: bounds.height)
    }

    required init?(coder: NSCoder) {
        nil
    }

    let container = SubviewsFactory.container
    let textField = SubviewsFactory.textField
    let cancelButton = SubviewsFactory.cancelButton
    let searchIcon = SubviewsFactory.searchIcon
    let clearButton = SubviewsFactory.clearButton

    private func addSubviews() {
        addSubview(container)
        addSubview(cancelButton)

        container.addSubview(textField)
        container.addSubview(searchIcon)
        container.addSubview(clearButton)
    }

    private func setUpLayout() {
        [
            container.topAnchor.constraint(greaterThanOrEqualTo: topAnchor),
            container.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor),
            container.centerYAnchor.constraint(equalTo: centerYAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: cancelButton.leadingAnchor, constant: -16),
            container.heightAnchor.constraint(equalToConstant: 36)
        ].activate()

        [
            cancelButton.topAnchor.constraint(equalTo: topAnchor),
            cancelButton.bottomAnchor.constraint(equalTo: bottomAnchor),
            cancelButton.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()

        [
            searchIcon.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 6),
            searchIcon.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            searchIcon.heightAnchor.constraint(equalToConstant: 24),
            searchIcon.widthAnchor.constraint(equalToConstant: 24)
        ].activate()

        [
            textField.leadingAnchor.constraint(equalTo: searchIcon.trailingAnchor, constant: 8),
            textField.topAnchor.constraint(equalTo: container.topAnchor, constant: 6),
            textField.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ].activate()

        [
            clearButton.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -8),
            clearButton.leadingAnchor.constraint(equalTo: textField.trailingAnchor, constant: 8),
            clearButton.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            clearButton.heightAnchor.constraint(equalToConstant: 24),
            clearButton.widthAnchor.constraint(equalToConstant: 24)
        ].activate()

        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

}

private enum SubviewsFactory {

    static var container: UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.BackgroundSecondary
        view.roundCorner(3)
        return view
    }

    static var textField: UITextField {
        let textField = UITextField(frame: .zero)
        textField.backgroundColor = ColorProvider.BackgroundSecondary
        textField.roundCorner(3)
        textField.autocapitalizationType = .none
        textField.returnKeyType = .search
        textField.placeholder = LocalString._general_search_placeholder
        textField.typingAttributes = FontManager.Default
        return textField
    }

    static var cancelButton: UIButton {
        let button = UIButton(type: .custom)
        button.setTitle(LocalString._general_cancel_button, for: .normal)
        button.setTitleColor(ColorProvider.TextNorm, for: .normal)
        return button
    }

    static var clearButton: UIButton {
        let button = UIButton(type: .custom)
        button.setImage(IconProvider.crossCircleFilled, for: .normal)
        button.tintColor = ColorProvider.IconWeak
        button.isHidden = true
        return button
    }

    static var searchIcon: UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.image = IconProvider.magnifier
        imageView.tintColor = ColorProvider.IconHint
        return imageView
    }

}
