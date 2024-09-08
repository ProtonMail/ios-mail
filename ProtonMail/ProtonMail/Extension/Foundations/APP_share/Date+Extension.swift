//
//  Data+Extension.swift
//  Proton Mail - Created on 4/30/15.
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

extension Date {
    enum Weekday: Int {
        case sunday = 1
        case monday, tuesday, wednesday, thursday, friday, saturday
      }

    // or an extension function to format your date
    func formattedWith(_ format: String, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone        // or as local time
        formatter.dateFormat = format
        return formatter.string(from: self)
    }

    func localizedString(locale: Locale = LocaleEnvironment.locale()) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        let template = DateFormatter
            .dateFormat(fromTemplate: "MMM dd jj mm", options: 0, locale: locale) ?? "MMM dd jj mm"
        // Some template will return `MM`, e.g. de_DE (24 H)
            .preg_replace(#"M{1,4}([\.,\\,\-,،]){0,1}"#, replaceto: "MMM$1", options: [.dotMatchesLineSeparators])
        formatter.dateFormat = template
        return formatter.string(from: self)
    }
    
    func formatLongDate() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: self)
    }

    var minute: Int {
        Calendar.current.component(.minute, from: self)
    }

    /// From 1 - 7, Sun is 1, Sat is 7
    var weekday: Int {
        Calendar.current.component(.weekday, from: self)
    }

    var hour: Int {
        Calendar.current.component(.hour, from: self)
    }

    func tomorrow(at hour: Int, minute: Int) -> Date? {
        guard let setDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self),
              let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: setDate) else { return nil }
        return tomorrow
    }

    func next(_ weekday: Weekday, hour: Int, minute: Int) -> Date? {
        let currentWeekday = self.weekday
        var diff = weekday.rawValue - currentWeekday
        if diff <= 0 { diff += 7 }

        guard let setDate = Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self),
              let next = Calendar.current.date(byAdding: .day, value: diff, to: setDate) else { return nil }
        return next
    }

    func add(_ component: Calendar.Component, value: Int) -> Date? {
        Calendar.current.date(byAdding: component, value: value, to: self)
    }

    func today(at hour: Int, minute: Int) -> Date? {
        return Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: self)
    }
}

// MARK: Count expiration time
extension Date {
    private static let expirationTimeFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.maximumUnitCount = 1
        formatter.unitsStyle = .full
        return formatter
    }()

    static func getReferenceDate(connectionStatus: ConnectionStatus = InternetConnectionStatusProvider.shared.status,
                                 processInfo: SystemUpTimeProtocol,
                                 deviceDate: Date = Date()) -> Date {
        guard connectionStatus != .initialize else {
            return Date.getOfflineReferenceDate(processInfo: processInfo, deviceDate: deviceDate)
        }

        let serverDate = Date(timeIntervalSince1970: processInfo.localServerTime)
        if connectionStatus.isConnected {
            return serverDate
        } else {
            // .NotReachable and other unknown cases
            return Date.getOfflineReferenceDate(processInfo: processInfo, deviceDate: deviceDate)
        }
    }

    private static func getOfflineReferenceDate(processInfo: SystemUpTimeProtocol, deviceDate: Date) -> Date {
        let serverDate = Date(timeIntervalSince1970: processInfo.localServerTime)
        let localSystemUpTime = processInfo.localSystemUpTime
        let nonZeroLocalSystemUpTime = localSystemUpTime == 0 ? Date().timeIntervalSince1970 : localSystemUpTime
        let diff = max(0, processInfo.systemUpTime - nonZeroLocalSystemUpTime)
        if diff > 0 {
            // The device doesn't reboot
            return serverDate.addingTimeInterval(diff)
        }
        return serverDate >= deviceDate ? serverDate : deviceDate
    }

    func countExpirationTime(
        connectionStatus: ConnectionStatus = InternetConnectionStatusProvider.shared.status,
        processInfo: SystemUpTimeProtocol
    ) -> String {
        let unixTime = Date.getReferenceDate(connectionStatus: connectionStatus, processInfo: processInfo)
        return Self.expirationTimeFormatter.string(from: unixTime, to: self)!
    }
}
