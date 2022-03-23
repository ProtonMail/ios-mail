//
//  SettingsGestureViewModel.swift
//  ProtonMail - Created on 2020/4/6.
//
//
//  Copyright (c) 2019 Proton Technologies AG
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

import Foundation

protocol SettingsGestureViewModel: AnyObject {
    var settingSwipeActionItems: [SwipeActionItems] { get set }
    var leftToRightAction: SwipeActionSettingType { get set }
    var rightToLeftAction: SwipeActionSettingType { get set }
}

class SettingsGestureViewModelImpl: SettingsGestureViewModel {

    var settingSwipeActionItems: [SwipeActionItems] = [.leftActionView, .left, .empty, .rightActionView, .right]

    private var swipeActionsCache: SwipeActionCacheProtocol

    var leftToRightAction: SwipeActionSettingType {
        get {
            return swipeActionsCache.leftToRightSwipeActionType
        }
        set {
            swipeActionsCache.leftToRightSwipeActionType = newValue
        }
    }

    var rightToLeftAction: SwipeActionSettingType {
        get {
            return swipeActionsCache.rightToLeftSwipeActionType
        }
        set {
            swipeActionsCache.rightToLeftSwipeActionType = newValue
        }
    }

    init(cache: SwipeActionCacheProtocol) {
        self.swipeActionsCache = cache
    }
}
