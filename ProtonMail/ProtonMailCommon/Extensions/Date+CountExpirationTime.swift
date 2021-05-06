//
//  Date+CountExpirationTime.swift
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

import Foundation

extension Date {

    var countExpirationTime: String {
        let distance: TimeInterval
        if #available(iOS 13.0, *) {
            distance = Date().distance(to: self)
        } else {
            distance = timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
        }

        if distance > 86400 {
            let day = Int(distance / 86400)
            return "\(day) " + (day > 1 ? LocalString._days : LocalString._day)
        } else if distance > 3600 {
            let hour = Int(distance / 3600)
            return "\(hour) " + (hour > 1 ? LocalString._hours : LocalString._hour)
        } else {
            let minute = Int(distance / 60)
            return "\(minute) " + (minute > 1 ? LocalString._minutes : LocalString._minute)
        }
    }

}
