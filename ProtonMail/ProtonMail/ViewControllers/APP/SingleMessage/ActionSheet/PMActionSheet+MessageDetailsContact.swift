//
//  PMActionSheet+MessageDetailsContact.swift
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
//  along with Proton Mail. If not, see <https://www.gnu.org/licenses/>.

import ProtonCore_DataModel
import ProtonCore_UIFoundations

extension PMActionSheet {

    static func messageDetailsContact(
        title: String,
        subtitle: String,
        showOfficialBadge: Bool,
        showOptionToBlockSender: Bool,
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheet {
        let closeItem = PMActionSheetPlainItem(
            title: nil,
            icon: IconProvider.cross,
            handler: { _ in action(.close) }
        )
        let header = PMActionSheetHeaderView(
            title: title,
            subtitle: subtitle,
            leftItem: closeItem,
            rightItem: nil,
            rightTitleViews: showOfficialBadge ? [OfficialBadge()] : []
        )

        var items = [
            copyAddress(action: action),
            copyName(action: action),
            composeTo(action: action),
            addToContacts(action: action)
        ]

        if UserInfo.isBlockSenderEnabled && showOptionToBlockSender {
            items.append(blockSender(action: action))
        }

        return PMActionSheet(headerView: header, itemGroups: [.init(items: items, style: .clickable)])
    }

    private static func copyAddress(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._copy_address,
            icon: IconProvider.squares
        ) { _ in action(.copyAddress) }
    }

    private static func copyName(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._copy_name,
            icon: IconProvider.squares
        ) { _ in action(.copyName) }
    }

    private static func composeTo(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._compose_to,
            icon: IconProvider.envelope
        ) { _ in action(.composeTo) }
    }

    private static func addToContacts(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: LocalString._add_to_contacts,
            icon: IconProvider.userPlus
        ) { _ in action(.addToContacts) }
    }

    private static func blockSender(
        action: @escaping (MessageDetailsContactActionSheetAction) -> Void
    ) -> PMActionSheetPlainItem {
        .init(
            title: L11n.BlockSender.blockActionTitleLong,
            icon: IconProvider.circleSlash
        ) { _ in action(.blockSender) }
    }
}
