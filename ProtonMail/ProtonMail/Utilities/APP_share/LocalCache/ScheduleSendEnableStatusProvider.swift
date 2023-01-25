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

enum ScheduledSendStatus {
    case enabled
    case disabled
    case notSet
}

protocol ScheduleSendEnableStatusProvider: AnyObject {
    func isScheduleSendEnabled(userID: UserID) -> ScheduledSendStatus
    func setScheduleSendStatus(enable: Bool, userID: UserID)
}

extension UserCachedStatus: ScheduleSendEnableStatusProvider {
    func isScheduleSendEnabled(userID: UserID) -> ScheduledSendStatus {
        guard let dict = getShared().object(forKey: Key.isScheduleSendEnabled) as? [String: Bool] else {
            return .notSet
        }

        if let explicitStatus = dict[userID.rawValue] {
            return explicitStatus ? .enabled : .disabled
        } else {
            return .notSet
        }
    }

    func setScheduleSendStatus(enable: Bool, userID: UserID) {
        var dictionaryToUpdate: [String: Bool] = [:]
        if let dict = getShared().object(forKey: Key.isScheduleSendEnabled) as? [String: Bool] {
            dictionaryToUpdate = dict
        }
        dictionaryToUpdate[userID.rawValue] = enable
        getShared().setValue(dictionaryToUpdate, forKey: Key.isScheduleSendEnabled)
    }
}
