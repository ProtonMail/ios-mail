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

enum MessageIDTag {}
typealias MessageID = Phantom<MessageIDTag, String>

extension MessageID {
    // Locally generated messageID is used by the temp message which is not uploaded to BE yet.
    var hasLocalFormat: Bool {
        UUID(uuidString: rawValue) != nil
    }

    static func generateLocalID() -> Self {
        return .init(UUID().uuidString)
    }
}
