//
//  MessageDataService+Error.swift
//  ProtonMail - Created on 4/12/18.
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


extension MessageDataService {
    enum RuntimeError : String, Error, CustomErrorVar {
        case cant_decrypt = "can't decrypt message body"
        case bad_draft
        var code: Int {
            get {
                return -1002000
            }
        }
        var desc: String {
            get {
                switch self {
                case .bad_draft:
                    return LocalString.unable_to_send_the_email
                default:
                    break
                }
                return self.rawValue
            }
        }
        var reason: String {
            get {
                switch self {
                case .bad_draft:
                    return LocalString._the_draft_incorrectly_sending_failed
                default:
                    break
                }
                return self.rawValue
            }
        }
    }
}
