//
//  SettingsGestureViewModel.swift
//  Proton Mail - Created on 2020/4/6.
//
//
//  Copyright (c) 2019 Proton AG
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

import Foundation
import ProtonCore_DataModel
import ProtonCore_Services

protocol SettingsGestureViewModel: AnyObject {
    var settingSwipeActionItems: [SwipeActionItems] { get set }
    var leftToRightAction: SwipeActionSettingType { get }
    var rightToLeftAction: SwipeActionSettingType { get }
}

final class SettingsGestureViewModelImpl: SettingsGestureViewModel {

    var settingSwipeActionItems: [SwipeActionItems] = [.rightActionView, .right, .empty, .leftActionView, .left]

    private var swipeActionsCache: SwipeActionCacheProtocol
    private let swipeActionInfo: SwipeActionInfo

    var leftToRightAction: SwipeActionSettingType {
        if let action = swipeActionsCache.leftToRightSwipeActionType {
            return action
        } else {
            return SwipeActionSettingType.convertFromServer(rawValue: self.swipeActionInfo.swipeRight) ?? .trash
        }
    }

    var rightToLeftAction: SwipeActionSettingType {
        if let action = swipeActionsCache.rightToLeftSwipeActionType {
            return action
        } else {
            return SwipeActionSettingType.convertFromServer(rawValue: self.swipeActionInfo.swipeLeft) ?? .archive
        }
    }

    init(cache: SwipeActionCacheProtocol,
         swipeActionInfo: SwipeActionInfo) {
        self.swipeActionsCache = cache
        self.swipeActionInfo = swipeActionInfo
    }
}

protocol SwipeActionInfo {
    var swipeLeft: Int { get }
    var swipeRight: Int { get }
}
extension UserInfo: SwipeActionInfo {}
