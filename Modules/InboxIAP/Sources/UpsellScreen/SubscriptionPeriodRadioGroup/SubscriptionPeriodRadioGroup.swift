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

import InboxDesignSystem
import SwiftUI

struct SubscriptionPeriodRadioGroup: View {
    let planInstances: [DisplayablePlanInstance]

    @Binding var selectedInstanceID: String

    var body: some View {
        VStack(spacing: .zero) {
            ForEach(planInstances, id: \.storeKitProductId) { planInstance in
                SubscriptionPeriodRadioButton(
                    planInstance: planInstance,
                    isSelected: planInstance.storeKitProductId == selectedInstanceID
                ) {
                    selectedInstanceID = planInstance.storeKitProductId
                }
                .tag(planInstance.storeKitProductId)
            }
        }
    }
}

#Preview {
    @Previewable @State var selectedInstanceID = DisplayablePlanInstance.previews[0].storeKitProductId

    SubscriptionPeriodRadioGroup(planInstances: DisplayablePlanInstance.previews, selectedInstanceID: $selectedInstanceID)
        .background(DS.Color.Brand.norm)
        .preferredColorScheme(.dark)
}
