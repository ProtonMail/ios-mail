//
//  PMActionSheet+MessageDetailsContact.swift
//  ProtonMail
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_UIFoundations

extension PMActionSheet {

    static func messageDetailsContact(
        for title: String,
        subTitle: String,
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheet {
        let closeItem = PMActionSheetPlainItem(
            title: nil,
            icon: IconProvider.cross,
            handler: { _ in action(.close) }
        )
        let header = PMActionSheetHeaderView(
            title: title,
            subtitle: subTitle,
            leftItem: closeItem,
            rightItem: nil
        )
        let items = [
            copyAddress(action: action),
            copyName(action: action),
            composeTo(action: action),
            addToContacts(action: action)
        ]
        return PMActionSheet(headerView: header, itemGroups: [.init(items: items, style: .clickable)])
    }

    static func copyAddress(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._copy_address,
            icon: IconProvider.squares
        ) { _ in action(.copyAddress) }
    }

    static func copyName(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._copy_name,
            icon: IconProvider.squares
        ) { _ in action(.copyName) }
    }

    static func composeTo(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._compose_to,
            icon: IconProvider.envelope
        ) { _ in action(.composeTo) }
    }

    static func addToContacts(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._add_to_contacts,
            icon: IconProvider.userPlus
        ) { _ in action(.addToContacts) }
    }

}
