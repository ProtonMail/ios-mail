//
//  SettingsSwipeActionSelectViewModel.swift
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
//

import Foundation
import ProtonCore_Services

protocol SettingsSwipeActionSelectViewModel {
    var settingSwipeActions: [SwipeActionSettingType] { get }
    var selectedAction: SwipeActionItems { get }

    func updateSwipeAction(_ action: SwipeActionSettingType, completion: (() -> Void)?)
    func currentAction() -> SwipeActionSettingType
    func isActionSyncable(_ action: SwipeActionSettingType) -> Bool
}

class SettingsSwipeActionSelectViewModelImpl: SettingsSwipeActionSelectViewModel {
    private let dependencies: Dependencies
    private(set) var settingSwipeActions: [SwipeActionSettingType] = [
        .none,
        .readAndUnread,
        .starAndUnstar,
        .trash,
        .labelAs,
        .moveTo,
        .archive,
        .spam
    ]

    private var swipeActionsCache: SwipeActionCacheProtocol

    let selectedAction: SwipeActionItems

    init(
        cache: SwipeActionCacheProtocol,
        selectedAction: SwipeActionItems,
        dependencies: Dependencies
    ) {
        self.swipeActionsCache = cache
        self.selectedAction = selectedAction
        self.dependencies = dependencies
    }

    func updateSwipeAction(_ action: SwipeActionSettingType, completion: (() -> Void)?) {
        if self.selectedAction == .left {
            dependencies.saveSwipeActionSetting.execute(preference: .left(action)) { _ in
                completion?()
            }
        } else {
            dependencies.saveSwipeActionSetting.execute(preference: .right(action)) { _ in
                completion?()
            }
        }
    }

    func currentAction() -> SwipeActionSettingType {
        if self.selectedAction == .left,
           let action = swipeActionsCache.rightToLeftSwipeActionType {
            return action
        } else if let action = swipeActionsCache.leftToRightSwipeActionType {
            return action
        } else {
            return .none
        }
    }

    func isActionSyncable(_ action: SwipeActionSettingType) -> Bool {
        return action.isSyncable
    }
}

extension SettingsSwipeActionSelectViewModelImpl {

    struct Dependencies {
        let saveSwipeActionSetting: SaveSwipeActionSettingForUsersUseCase
    }
}
