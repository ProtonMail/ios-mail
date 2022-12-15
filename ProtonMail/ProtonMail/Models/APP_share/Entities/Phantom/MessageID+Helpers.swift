// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import Foundation

extension MessageID {

    /// Push notification identifier
    ///
    /// This logic replicates the logic used in backend to identify a push notification sent for a specific
    /// message. This notificationId allows for example to clear a push notification from the Notification
    /// Center once the message has been read.
    var notificationId: String? {
        let hexStr = Data(rawValue.utf8).stringFromToken()
        guard hexStr.count > 19 else {
            SystemLogger.log(
                message: "notificationId is nil because messageId length is \(hexStr.count)",
                category: .pushNotification,
                isError: true
            )
            return nil
        }

        let startIndex = hexStr.startIndex
        let firstPart = hexStr[startIndex...hexStr.index(startIndex, offsetBy: 7)]
        let secondPart = hexStr[hexStr.index(startIndex, offsetBy: 8)...hexStr.index(startIndex, offsetBy: 11)]
        let thirdPart = hexStr[hexStr.index(startIndex, offsetBy: 12)...hexStr.index(startIndex, offsetBy: 15)]
        let fourthPart = hexStr[hexStr.index(startIndex, offsetBy: 16)...hexStr.index(startIndex, offsetBy: 19)]
        let uuid = "\(firstPart)-\(secondPart)-\(thirdPart)-\(fourthPart)"

        return uuid
    }
}
