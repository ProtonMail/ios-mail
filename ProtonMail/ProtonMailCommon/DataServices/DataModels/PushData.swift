//
//  PushData.swift
//  ProtonMail - Created on 12/13/17.
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

struct PushData: Codable {
    let badge: Int
    let body: String
    let sender: Sender
    let messageId: String
    // Unused on iOS fields:
    //    let title: String
    //    let subtitle: String
    //    let vibrate: Int
    //    let sound: Int
    //    let largeIcon: String
    //    let smallIcon: String

    static func parse(with json: String) -> PushData? {
        guard let data = json.data(using: .utf8),
            let push = try? JSONDecoder().decode(Push.self, from: data) else {
            return nil
        }
        return push.data
    }
}

struct Push: Codable {
    let data: PushData
    // Unused on iOS fields
    //    let type: String
    //    let version: Int
}
