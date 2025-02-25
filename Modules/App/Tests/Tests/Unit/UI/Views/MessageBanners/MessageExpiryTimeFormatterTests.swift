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

@testable import ProtonMail
import Testing

struct MessageExpiryTimeFormatterTests {
    enum Timestamp: Int {
        case _2025_02_22_15_30_00 = 1740238200
    }
    
    @Test("Formats expiration time correctly", arguments: [
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:30:01"), "Expired"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:30:00"), "0 seconds"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:29:51"), "9 seconds"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:29:45"), "15 seconds"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:29:00"), "1 minute"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 15:00:00"), "30 minutes"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-22 12:13:59"), "3 hours, 16 minutes"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-12 09:11:00"), "10 days, 6 hours, 19 minutes"),
        (Timestamp._2025_02_22_15_30_00, Date.fixture("2025-02-12 15:31:00"), "9 days, 23 hours, 59 minutes")
    ])
    func formattedTime(timestamp: Timestamp, currentDate: Date, expectedFormattedTime: String) {
        let formattedTime = MessageExpiryTimeFormatter.string(
            from: timestamp.rawValue,
            currentDate: currentDate
        )
        
        #expect(formattedTime == expectedFormattedTime)
    }
}
