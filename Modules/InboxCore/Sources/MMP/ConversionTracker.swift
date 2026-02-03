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

import AdAttributionKit

protocol ConversionTracker {
    func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseValue,
        lockPostback: Bool
    ) async throws
}

@available(iOS 17.4, *)
struct AdAttributionKitTracker: ConversionTracker {
    func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseValue,
        lockPostback: Bool
    ) async throws {
        try await Postback.updateConversionValue(
            fineConversionValue,
            coarseConversionValue: coarseConversionValue.adAttributionKitValue,
            lockPostback: lockPostback
        )
    }
}

struct NoTracking: ConversionTracker {
    func updateConversionValue(
        _ fineConversionValue: Int,
        coarseConversionValue: CoarseValue,
        lockPostback: Bool
    ) async throws {}
}

func makeConversionTracker() -> ConversionTracker {
    if #available(iOS 17.4, *) {
        AdAttributionKitTracker()
    } else {
        NoTracking()
    }
}
