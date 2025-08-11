// Copyright (c) 2025 Proton Technologies AG
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
import InboxCore

struct StorageInfo: Hashable {
    let usedSpace: Int64
    let maxSpace: Int64

    private let pctFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()

    var percentageOfUsedSpace: Double {
        guard maxSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(maxSpace)
    }

    var formattedStorage: LocalizedStringResource {
        let usedSpaceFormatted = pctFormatter.string(from: NSNumber(value: percentageOfUsedSpace)) ?? "0"
        let maxSpaceFormatted = Formatter.binaryBytesFormatter.string(fromByteCount: maxSpace)

        return L10n.Settings.storagePctOutOf(pct: usedSpaceFormatted, total: maxSpaceFormatted)
    }

    var isNearingOutOfStorage: Bool {
        percentageOfUsedSpace >= 0.8
    }
}
