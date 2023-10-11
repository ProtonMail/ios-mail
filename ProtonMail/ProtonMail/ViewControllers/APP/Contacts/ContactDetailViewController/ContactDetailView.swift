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

final class ContactDetailView: UIView {
    let tableView = SubViewsFactory.tableView

    let tableHeaderView = SubViewsFactory.tableHeaderView
    let profileImageView = SubViewsFactory.profileImageView
    let displayNameLabel = SubViewsFactory.displayNameLabel
    let shortNameLabel = SubViewsFactory.shortNameLabel
    let callContactImageView = SubViewsFactory.callContactImageView
    let callContactLabel = SubViewsFactory.callContactLabel
    let emailContactImageView = SubViewsFactory.emailContactImageView
    let emailContactLabel = SubViewsFactory.emailContactLabel
    let shareContactImageView = SubViewsFactory.shareContactImageView
    let shareContactLabel = SubViewsFactory.shareContactLabel

    init() {
        super.init(frame: .zero)
        addSubViews()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func addSubViews() {
        addSubview(tableView)

        tableHeaderView.addSubview(profileImageView)
        tableHeaderView.addSubview(displayNameLabel)
        tableHeaderView.addSubview(shortNameLabel)
        tableHeaderView.addSubview(callContactImageView)
        tableHeaderView.addSubview(callContactLabel)
        tableHeaderView.addSubview(emailContactImageView)
        tableHeaderView.addSubview(emailContactLabel)
        tableHeaderView.addSubview(shareContactImageView)
        tableHeaderView.addSubview(shareContactLabel)
        tableView.tableHeaderView = tableHeaderView
    }

    private func setupLayout() {
        tableView.fillSuperview()
        [
            tableHeaderView.widthAnchor.constraint(equalTo: tableView.widthAnchor)
        ].activate()
        [
            profileImageView.topAnchor.constraint(equalTo: tableHeaderView.topAnchor),
            profileImageView.heightAnchor.constraint(equalToConstant: 80),
            profileImageView.widthAnchor.constraint(equalToConstant: 80),
            profileImageView.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            shortNameLabel.centerXAnchor.constraint(equalTo: profileImageView.centerXAnchor),
            shortNameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor),
            shortNameLabel.widthAnchor.constraint(equalTo: profileImageView.widthAnchor),
            displayNameLabel.topAnchor.constraint(equalTo: profileImageView.bottomAnchor, constant: 12),
            displayNameLabel.leadingAnchor.constraint(equalTo: tableHeaderView.leadingAnchor, constant: 8),
            displayNameLabel.trailingAnchor.constraint(equalTo: tableHeaderView.trailingAnchor, constant: -8)
        ].activate()

        [
            callContactImageView.topAnchor.constraint(equalTo: displayNameLabel.bottomAnchor, constant: 20),
            callContactImageView.widthAnchor.constraint(equalToConstant: 56),
            callContactImageView.heightAnchor.constraint(equalToConstant: 56),
            callContactImageView.centerXAnchor.constraint(equalTo: tableHeaderView.centerXAnchor),
            callContactLabel.centerXAnchor.constraint(equalTo: callContactImageView.centerXAnchor),
            callContactLabel.topAnchor.constraint(equalTo: callContactImageView.bottomAnchor, constant: 8),
            callContactLabel.bottomAnchor.constraint(equalTo: tableHeaderView.bottomAnchor, constant: -8),
            callContactLabel.widthAnchor.constraint(equalToConstant: 80)
        ].activate()

        [
            emailContactImageView.topAnchor.constraint(equalTo: callContactImageView.topAnchor),
            emailContactImageView.widthAnchor.constraint(equalTo: callContactImageView.widthAnchor),
            emailContactImageView.heightAnchor.constraint(equalTo: callContactImageView.heightAnchor),
            emailContactImageView.trailingAnchor.constraint(equalTo: callContactImageView.leadingAnchor, constant: -48),
            emailContactLabel.centerXAnchor.constraint(equalTo: emailContactImageView.centerXAnchor),
            emailContactLabel.topAnchor.constraint(equalTo: emailContactImageView.bottomAnchor, constant: 8),
            emailContactLabel.widthAnchor.constraint(equalToConstant: 80)
        ].activate()

        [
            shareContactImageView.topAnchor.constraint(equalTo: callContactImageView.topAnchor),
            shareContactImageView.widthAnchor.constraint(equalTo: callContactImageView.widthAnchor),
            shareContactImageView.heightAnchor.constraint(equalTo: callContactImageView.heightAnchor),
            shareContactImageView.leadingAnchor.constraint(equalTo: callContactImageView.trailingAnchor, constant: 48),
            shareContactLabel.centerXAnchor.constraint(equalTo: shareContactImageView.centerXAnchor),
            shareContactLabel.topAnchor.constraint(equalTo: shareContactImageView.bottomAnchor, constant: 8),
            shareContactLabel.widthAnchor.constraint(equalToConstant: 80)
        ].activate()
    }
}

private enum SubViewsFactory {
    static var tableView: UITableView {
        let view = UITableView(frame: .zero)
        view.backgroundColor = ColorProvider.BackgroundNorm
        view.separatorStyle = .none
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
        view.layer.cornerRadius = 40
        view.layer.masksToBounds = true
        return view
    }

    static var shortNameLabel: UILabel {
        let view = UILabel()
        view.backgroundColor = ColorProvider.InteractionWeak
        view.layer.cornerRadius = 40
        view.layer.masksToBounds = true
        view.textAlignment = .center
        return view
    }

    static var displayNameLabel: UILabel {
        let view = UILabel()
        view.font = .systemFont(ofSize: 17)
        return view
    }

    static var callContactImageView: UIImageView {
        let view = UIImageView(frame: .zero)
        view.image = IconProvider.phone
            .resizableImage(withCapInsets: .init(all: -4), resizingMode: .stretch)
        view.contentMode = .center
        view.backgroundColor = .lightGray
        view.tintColor = .white
        view.roundCorner(28)
        return view
    }

    static var callContactLabel: UILabel {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textAlignment = .center
        view.textColor = ColorProvider.TextWeak
        view.text = LocalString._contacts_call_contact_title
        return view
    }

    static var emailContactImageView: UIImageView {
        let view = UIImageView(frame: .zero)
        view.image = IconProvider.penSquare
            .resizableImage(withCapInsets: .init(all: -4), resizingMode: .stretch)
        view.contentMode = .center
        view.backgroundColor = .lightGray
        view.tintColor = .white
        view.roundCorner(28)
        return view
    }

    static var emailContactLabel: UILabel {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textAlignment = .center
        view.textColor = ColorProvider.TextWeak
        view.text = LocalString._contacts_email_contact_title
        return view
    }

    static var shareContactImageView: UIImageView {
        let view = UIImageView(frame: .zero)
        view.image = IconProvider.arrowUpFromSquare
            .resizableImage(withCapInsets: .init(all: -4), resizingMode: .stretch)
        view.contentMode = .center
        view.backgroundColor = ColorProvider.BrandNorm
        view.tintColor = .white
        view.roundCorner(28)
        return view
    }

    static var shareContactLabel: UILabel {
        let view = UILabel()
        view.font = .systemFont(ofSize: 12)
        view.textAlignment = .center
        view.textColor = ColorProvider.TextWeak
        view.text = LocalString._contacts_share_contact_action
        return view
    }
}
