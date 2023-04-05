//
//  MessageViewActionSheetPresenter.swift
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

class MessageViewActionSheetPresenter {

    func present(
        on viewController: UIViewController,
        listener: PMActionSheetEventsListener?,
        viewModel: ActionSheetViewModel,
        action: @escaping (MessageViewActionSheetAction) -> Void) {
            let headerView = PMActionSheetHeaderView(
                title: viewModel.title,
                subtitle: nil,
                leftItem: .right(IconProvider.cross),
                rightItem: nil,
                leftItemHandler: {
                    action(.dismiss)
                }
            )

            let actionGroups: [PMActionSheetItemGroup] = Dictionary(grouping: viewModel.items, by: \.group)
                .sorted(by: { $0.key.order < $1.key.order })
                .map { (key: MessageViewActionSheetGroup, value: [MessageViewActionSheetAction]) in
                    let actions: [PMActionSheetItem] = value.map { item in
                        let style: PMActionSheetItem.Style
                        if let icon = item.icon {
                            style = .default(icon, item.title ?? "")
                        } else {
                            style = .text(item.title ?? "")
                        }
                        return PMActionSheetItem(style: style) { _ in
                            action(item)
                        }
                    }
                    return PMActionSheetItemGroup(title: key.title, items: actions, style: .clickable)
                }

            let actionSheet = PMActionSheet(headerView: headerView, itemGroups: actionGroups) /*, maximumOccupy: 0.7) */
            actionSheet.eventsListener = listener
            actionSheet.presentAt(viewController, hasTopConstant: false, animated: true)
            delay(0.3) {
                if UIAccessibility.isVoiceOverRunning {
                    UIAccessibility.post(notification: .screenChanged, argument: actionSheet)
                }
            }
        }
}
