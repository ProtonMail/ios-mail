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

    // you can create a read-only computed property to return just the nanoseconds as Int
    var nanosecond: Int {
        let calendar = (Calendar.current as NSCalendar)
        let component = calendar.components(.nanosecond, from: self)
        let seconds = component.nanosecond
        return seconds ?? -1
    }

    // or an extension function to format your date
    func formattedWith(_ format: String, timeZone: TimeZone = .autoupdatingCurrent) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone        // or as local time
        formatter.dateFormat = format
        return formatter.string(from: self)
    }
}

// MARK: Count expiration time
extension Date {

    static func getReferenceDate(processInfo: SystemUpTimeProtocol?,
                                 reachability: Reachability? = sharedInternetReachability) -> Date {
        #if APP_EXTENSION
            return Date.getReferenceDate(reachability: nil,
                                         processInfo: processInfo)
        #else
            return Date.getReferenceDate(reachability: sharedInternetReachability,
                                         processInfo: processInfo)
        #endif
    }

    static func getReferenceDate(reachability: Reachability?,
                                 processInfo: SystemUpTimeProtocol?,
                                 deviceDate: Date = Date()) -> Date {
        guard let reachability = reachability,
              let processInfo = processInfo else {
            // App extension doesn't have reachability
            return Date.getOfflineReferenceDate(processInfo: processInfo, deviceDate: deviceDate)
        }

        let status = reachability.currentReachabilityStatus()
        let serverDate = Date(timeIntervalSince1970: processInfo.localServerTime)
        switch status {
        case .ReachableViaWWAN, .ReachableViaWiFi:
            return serverDate
        default:
            // .NotReachable and other unknown cases
            return Date.getOfflineReferenceDate(processInfo: processInfo, deviceDate: deviceDate)
        }
    }

    private static func getOfflineReferenceDate(processInfo: SystemUpTimeProtocol?, deviceDate: Date) -> Date {
        guard let processInfo = processInfo else {
            return deviceDate
        }

        let serverDate = Date(timeIntervalSince1970: processInfo.localServerTime)
        let diff = max(0, processInfo.systemUpTime - processInfo.localSystemUpTime)
        if diff > 0 {
            // The device doesn't reboot
            return serverDate.addingTimeInterval(diff)
        }
        return serverDate >= deviceDate ? serverDate: deviceDate
    }

    func countExpirationTime(processInfo: SystemUpTimeProtocol?,
                             reachability: Reachability? = sharedInternetReachability) -> String {
        let distance: TimeInterval
        let unixTime = Date.getReferenceDate(processInfo: processInfo, reachability: reachability)
        if #available(iOS 13.0, *) {
            distance = unixTime.distance(to: self) + 60
        } else {
            distance = timeIntervalSinceReferenceDate - unixTime.timeIntervalSinceReferenceDate + 60
        }

        if distance > 86_400 {
            let day = Int(distance / 86_400)
            return String.localizedStringWithFormat(LocalString._day, day)
        } else if distance > 3_600 {
            let hour = Int(distance / 3_600)
            return String.localizedStringWithFormat(LocalString._hour, hour)
        } else {
            let minute = Int(distance / 60)
            return String.localizedStringWithFormat(LocalString._minute, minute)
        }
    }

}
