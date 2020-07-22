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
    var setting_swipe_action_items : [SSwipeActionItems] { get set}
    var setting_swipe_actions : [MessageSwipeAction] { get set }
    var userInfo: UserInfo { get }
    var user: UserManager { get }
    
    func updateUserSwipeAction(isLeft : Bool,
                               action: MessageSwipeAction,
                               completion: @escaping CompletionBlock)
}

class SettingsGestureViewModelImpl: SettingsGestureViewModel {
    
    var setting_swipe_action_items : [SSwipeActionItems] = [.left, .right]
    var setting_swipe_actions : [MessageSwipeAction]     = [.trash, .spam,
                                                            .star, .archive, .unread]
    let user: UserManager
    let users: UsersManager
    
    var userInfo: UserInfo {
        get {
            return self.user.userInfo
        }
    }
    
    init(user: UserManager, users: UsersManager) {
        self.user = user
        self.users = users
    }
    
    func updateUserSwipeAction(isLeft: Bool, action: MessageSwipeAction, completion: @escaping CompletionBlock) {
        self.user.userService.updateUserSwipeAction(auth: self.user.auth, userInfo: self.userInfo, isLeft: isLeft, action: action) { task, res, err in
            self.users.onSave(userManger: self.user)
            completion(task, res, err)
        }
    }
}
