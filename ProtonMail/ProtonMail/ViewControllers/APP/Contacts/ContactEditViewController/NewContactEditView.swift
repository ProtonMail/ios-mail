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

import ProtonCoreUIFoundations
import UIKit

final class NewContactEditView: UIView {
    let tableView = SubViewsFactory.tableView

    let tableHeaderView = SubViewsFactory.tableHeaderView
    let profileImageView = SubViewsFactory.profileImageView
    let photoButton = SubViewsFactory.photoButton

    let displayNameField = SubViewsFactory.displayNameField
    let disPlaySeparator = SubViewsFactory.makeSeparatorView()

    let firstNameField = SubViewsFactory.firstNameField
    let firstNameSeparator = SubViewsFactory.makeSeparatorView()

    let lastNameField = SubViewsFactory.lastNameField
    let lastNameSeparator = SubViewsFactory.makeSeparatorView()

    init() {
        super.init(frame: .zero)
        addSubviews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        nil
    }

    private func addSubviews() {
        addSubview(tableView)

        tableHeaderView.addSubview(profileImageView)
        tableHeaderView.addSubview(photoButton)
        tableHeaderView.addSubview(displayNameField)
        tableHeaderView.addSubview(disPlaySeparator)
        tableHeaderView.addSubview(firstNameField)
        tableHeaderView.addSubview(firstNameSeparator)
        tableHeaderView.addSubview(lastNameField)
        tableHeaderView.addSubview(lastNameSeparator)
        tableView.tableHeaderView = tableHeaderView
    }

    private func setupLayout() {
        tableView.fillSuperview()
        [
            tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        ].activate()
        tableHeaderView.translatesAutoresizingMaskIntoConstraints = false
        [
            profileImageView.heightAnchor.constraint(equalToConstant: 80.0),
            profileImageView.widthAnchor.constraint(equalToConstant: 80.0),
            profileImageView.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            profileImageView.topAnchor.constraint(equalTo: tableHeaderView.topAnchor),
            photoButton.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 4),
            photoButton.leadingAnchor.constraint(equalTo: tableHeaderView.safeAreaLayoutGuide.leadingAnchor),
            photoButton.trailingAnchor.constraint(equalTo: tableHeaderView.safeAreaLayoutGuide.trailingAnchor)
        ].activate()

        [
            displayNameField.topAnchor.constraint(equalTo: photoButton.bottomAnchor, constant: 16),
            displayNameField.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor, constant: 16),
            displayNameField.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor, constant: -16),
            disPlaySeparator.topAnchor.constraint(equalTo: displayNameField.bottomAnchor, constant: 8),
            disPlaySeparator.leadingAnchor.constraint(equalTo: displayNameField.leadingAnchor),
            disPlaySeparator.trailingAnchor.constraint(equalTo: displayNameField.trailingAnchor),
            firstNameField.topAnchor.constraint(equalTo: disPlaySeparator.bottomAnchor, constant: 16),
            firstNameField.leadingAnchor.constraint(equalTo: displayNameField.leadingAnchor),
            firstNameField.trailingAnchor.constraint(equalTo: displayNameField.trailingAnchor),
            firstNameSeparator.topAnchor.constraint(equalTo: firstNameField.bottomAnchor, constant: 8),
            firstNameSeparator.leadingAnchor.constraint(equalTo: displayNameField.leadingAnchor),
            firstNameSeparator.trailingAnchor.constraint(equalTo: displayNameField.trailingAnchor),
            lastNameField.topAnchor.constraint(equalTo: firstNameSeparator.bottomAnchor, constant: 16),
            lastNameField.leadingAnchor.constraint(equalTo: firstNameField.leadingAnchor),
            lastNameField.trailingAnchor.constraint(equalTo: firstNameField.trailingAnchor),
            lastNameSeparator.topAnchor.constraint(equalTo: lastNameField.bottomAnchor, constant: 8),
            lastNameSeparator.leadingAnchor.constraint(equalTo: displayNameField.leadingAnchor),
            lastNameSeparator.trailingAnchor.constraint(equalTo: displayNameField.trailingAnchor),
            lastNameSeparator.bottomAnchor.constraint(equalTo: tableHeaderView.bottomAnchor, constant: -36)
        ].activate()
    }
}

private enum SubViewsFactory {
    static var tableView: UITableView {
        let view = UITableView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.allowsSelectionDuringEditing = true
        return view
    }

    static var tableHeaderView: UIView {
        let view = UIView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        return view
    }

    static var profileImageView: UIImageView {
        let view = UIImageView(frame: .zero)
        view.contentMode = .scaleAspectFill
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 40.0
        view.layer.masksToBounds = true
        return view
    }

    static var photoButton: UIButton {
        let view = UIButton(frame: .zero)
        view.titleLabel?.font = UIFont.adjustedFont(forTextStyle: .caption1, weight: .semibold)
        view.setTitleColor(ColorProvider.InteractionNorm, for: .normal)
        view.setTitle("", for: .normal)
        return view
    }

    static var displayNameField: UITextField {
        let view = UITextField()
        view.attributedPlaceholder = L10n.ContactEdit.displayNamePlaceholder
            .apply(style: FontManager.DefaultStrong.foregroundColor(ColorProvider.TextWeak))
        return view
    }

    static var firstNameField: UITextField {
        let view = UITextField()
        view.attributedPlaceholder = L10n.ContactEdit.firstNamePlaceholder
            .apply(style: FontManager.Default.foregroundColor(ColorProvider.TextWeak))
        return view
    }

    static var lastNameField: UITextField {
        let view = UITextField()
        view.attributedPlaceholder = L10n.ContactEdit.lastNamePlaceholder
            .apply(style: FontManager.Default.foregroundColor(ColorProvider.TextWeak))
        return view
    }

    static func makeSeparatorView() -> UIView {
        let view = UIView()
        view.backgroundColor = ColorProvider.SeparatorNorm
        [
            view.heightAnchor.constraint(equalToConstant: 1)
        ].activate()
        return view
    }
}
