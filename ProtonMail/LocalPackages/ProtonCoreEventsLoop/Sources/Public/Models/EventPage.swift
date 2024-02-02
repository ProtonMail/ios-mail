// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and ProtonCore.
//
// ProtonCore is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonCore is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonCore. If not, see https://www.gnu.org/licenses/.

import Foundation

public protocol EventPage {
    var eventID: String { get }
    var refresh: Int { get }
    var more: Int { get }
}

extension EventPage {

    var requiresClearCache: Bool {
        RefreshStatus(rawValue: refresh).contains(.all)
    }

    var requireClearContactCache: Bool {
        RefreshStatus(rawValue: refresh).contains(.contacts)
    }

    var requireClearMailCache: Bool {
        RefreshStatus(rawValue: refresh).contains(.mail)
    }

    var hasMorePages: Bool {
        more == 1
    }

}

private struct RefreshStatus: OptionSet {
    let rawValue: Int
    // 255 means throw out client cache and reload everything from server, 1 is mail, 2 is contacts
    static let upToDate = RefreshStatus([])
    /// When the user was delinquent and is not anymore
    static let mail     = RefreshStatus(rawValue: 1 << 0)
    /// When the user cleared his contacts
    static let contacts = RefreshStatus(rawValue: 1 << 1)
    /// When given ID < lowest ID stored (3 weeks old)
    static let all      = RefreshStatus(rawValue: 0xFF)
}
