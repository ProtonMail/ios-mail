//
//  SwipeAction.swift
//  ProtonMail - Created on 12/6/18.
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

enum MessageSwipeAction : Int, CustomStringConvertible {
    case trash = 0
    case spam = 1
    case star = 2
    case archive = 3
    case unread = 4
    
    var description : String {
        get {
            switch(self) {
            case .trash:
                return LocalString._locations_trash_desc //Trash
            case .spam:
                return LocalString._locations_spam_desc
            case .star:
                return LocalString._star
            case .archive:
                return LocalString._locations_archive_desc
            case .unread:
                return LocalString._mark_as_unread_short
            }
        }
    }
    
    var actionColor: UIColor {
        switch(self) {
        case .trash:
            return UIColor.red
        default:
            return UIColor.ProtonMail.MessageActionTintColor
        }
    }
}

