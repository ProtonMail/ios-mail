//
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

import proton_app_uniffi

extension UpsellScreenModel {
    static func preview(entryPoint: UpsellEntryPoint, upsellType: UpsellType) -> UpsellScreenModel {
        let planInstances: [DisplayablePlanInstance]

        switch upsellType {
        case .standard:
            planInstances = DisplayablePlanInstance.previews
        case .blackFriday(.wave1):
            planInstances = [DisplayablePlanInstance.blackFridayPreviews[0]]
        case .blackFriday(.wave2):
            planInstances = [DisplayablePlanInstance.blackFridayPreviews[1]]
        }

        return .init(
            planName: "Mail Plus",
            planInstances: planInstances,
            entryPoint: entryPoint,
            upsellType: upsellType,
            purchaseActionPerformer: .dummy
        )
    }
}
