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

enum SpamScore: Int, CustomStringConvertible, Equatable, Hashable {
    /// PM email from outside but DMARC failed or DKIM!=pass, causes client warning!
    case pmSpoof = 100
    /// dmarc=fail, causes client warning!
    case dmarcFail = 101
    /// Detected as phishing by the PhishingPattern system
    case pmPhishing = 102
    /// dmarc=fail but p=none
    case dmarcFailPNone = 103
    /// Detected as spam by the PhishingPattern system
    case pmSpam = 104
    case others = 0

    init(rawValue: Int) {
        switch rawValue {
        case 100:
            self = .pmSpoof
        case 101:
            self = .dmarcFail
        case 102:
            self = .pmPhishing
        case 104:
            self = .pmSpam
        default:
            self = .others
        }
    }

    var description: String {
        switch self {
        case .pmSpoof:
            return LocalString._messages_spam_100_warning
        case .dmarcFail:
            return LocalString._messages_spam_101_warning
        case .pmPhishing:
            return LocalString._messages_spam_102_warning
        default:
            return ""
        }
    }
}
