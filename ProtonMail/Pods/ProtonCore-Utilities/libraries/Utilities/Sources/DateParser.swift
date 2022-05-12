//
//  DateParser.swift
//  ProtonCore-Utilities - Created on 7/28/21.
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

public enum DateParser {
    
    /// locale code
    enum LocaleCode: String {
        case en_us = "en_US_POSIX"
    }
    
    /// date format
    enum LocaleFormat: String {
        case en_us = "EEE, dd MMM yyyy HH:mm:ss zzz"
    }
    
    /// convert a string datetime to a Date object
    ///   notes::if seeing more failure, we can try to use ISO8601DateFormatter() as a fallback
    /// - Parameter serverDate: server response header Date field
    /// - Returns: parsed date
    public static func parse(time serverDate: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.calendar = .some(.init(identifier: .gregorian))
        /// default locale must be set. use en_US matches with server response time
        dateFormatter.locale = Locale(identifier: LocaleCode.en_us.rawValue)
        /// dataformat is depends on server response. it shoude always like: "EEE, dd MMM yyyy HH:mm:ss zzz"
        dateFormatter.dateFormat = LocaleFormat.en_us.rawValue
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return dateFormatter.date(from: serverDate)
    }
}
