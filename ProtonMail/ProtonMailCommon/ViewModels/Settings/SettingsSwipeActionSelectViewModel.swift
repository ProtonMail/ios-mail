//
//  SettingsSwipeActionSelectViewModel.swift
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
//

import Foundation

protocol SettingsSwipeActionSelectViewModel {
    var settingSwipeActions: [SwipeActionSettingType] { get }
    var selectedAction: SwipeActionItems { get }

    func updateSwipeAction(_ action: SwipeActionSettingType)
    func currentAction() -> SwipeActionSettingType
}

class SettingsSwipeActionSelectViewModelImpl: SettingsSwipeActionSelectViewModel {
    private(set) var settingSwipeActions: [SwipeActionSettingType] = [.none,
                                                         .readAndUnread,
                                                         .starAndUnstar,
                                                         .trash,
                                                         /*.labelAs, .moveTo,*/
                                                         .archive,
                                                         .spam]

    private var swipeActionsCache: SwipeActionCacheProtocol

    let selectedAction: SwipeActionItems

    init(cache: SwipeActionCacheProtocol, selectedAction: SwipeActionItems) {
        self.swipeActionsCache = cache
        self.selectedAction = selectedAction
    }

    func updateSwipeAction(_ action: SwipeActionSettingType) {
        if self.selectedAction == .left {
            swipeActionsCache.leftToRightSwipeActionType = action
        } else {
            swipeActionsCache.rightToLeftSwipeActionType = action
        }
    }

    func currentAction() -> SwipeActionSettingType {
        if self.selectedAction == .left {
            return swipeActionsCache.leftToRightSwipeActionType
        } else {
            return swipeActionsCache.rightToLeftSwipeActionType
        }
    }
}
