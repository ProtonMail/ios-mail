//
//  MessageSpamScore.swift
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

extension Message {
    enum SpamScore: Int, CustomStringConvertible {
        case spam_100 = 100
        case spam_101 = 101
        case spam_102 = 102
        case others = 0

        var description: String {
            get {
                switch self {
                case .spam_100:
                    return LocalString._messages_spam_100_warning
                case .spam_101:
                    return LocalString._messages_spam_101_warning
                case .spam_102:
                    return LocalString._messages_spam_102_warning
                case .others:
                    return ""
                }
            }
        }
    }
}
