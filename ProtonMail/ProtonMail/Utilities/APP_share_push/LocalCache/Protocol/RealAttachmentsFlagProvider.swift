// Copyright (c) 2022 Proton AG
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

protocol RealAttachmentsFlagProvider: AnyObject {
    var realAttachments: Bool { get }

    func set(realAttachments: Bool, sessionID: String)
}

extension UserCachedStatus: RealAttachmentsFlagProvider {
    var realAttachments: Bool {
        guard let dict = getShared().object(forKey: Key.realAttachments) as? [String: Bool],
              let sessionID = primaryUserSessionId else {
            return false
        }
        return dict[sessionID] ?? false
    }

    func set(realAttachments: Bool, sessionID: String) {
        var dictionaryToUpdate: [String: Bool] = [:]
        if let dict = getShared().object(forKey: UserCachedStatus.Key.realAttachments) as? [String: Bool] {
            dictionaryToUpdate = dict
        }
        dictionaryToUpdate[sessionID] = realAttachments
        setValue(dictionaryToUpdate, forKey: Key.realAttachments)
    }
}
