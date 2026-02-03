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

struct ConversionValue: OptionSet, Equatable {
    let rawValue: UInt8

    init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    // Bit 0: Sign-in / account created
    static let appInstalled: ConversionValue = []
    static let signedIn = ConversionValue(rawValue: 1 << 0)

    // Bit 1: First emails sent/received
    static let firstActionPerformed = ConversionValue(rawValue: 1 << 1)

    // Bit 2: Subscription cycle
    static let monthlySubscription: ConversionValue = []
    static let yearlySubscription = ConversionValue(rawValue: 1 << 2)

    // Bits 3-4: Plan tier (2-bit field)
    // Value 0 (Plus): 00 - bit 3=0, bit 4=0
    // Value 1 (Unlimited): 01 - bit 3=1, bit 4=0
    // Value 2 (Reserved): 10 - bit 3=0, bit 4=1
    // Value 3 (Reserved): 11 - bit 3=1, bit 4=1
    static let planPlus: ConversionValue = []
    static let planUnlimited = ConversionValue(rawValue: 1 << 3)

    // Bit 5: Paid subscription flag
    static let paidSubscription = ConversionValue(rawValue: 1 << 5)
}
