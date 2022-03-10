//
//  MenuSection.swift
//  ProtonMail
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

enum MenuSection {
    case inboxes
    case folders
    case labels
    case more
    case unknown
    
    var title: String {
        switch self {
        case .inboxes: return LocalString._locations_inbox_title
        case .folders: return LocalString._folders
        case .labels: return LocalString._labels
        // todo: the translation title could be wrong
        case .more: return LocalString._general_more
        default:
            return ""
        }
    }
}
