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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

public struct OnboardingUpsellScreen: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var toastStateStore: ToastStateStore
    @State private var model: OnboardingUpsellScreenModel

    public var body: some View {
        ScrollView {
            LazyVStack(pinnedViews: [.sectionHeaders]) {
                Section {
                    planTiles
                        .padding(.horizontal, DS.Spacing.large)
                } header: {
                    VStack(spacing: DS.Spacing.small) {
                        chooseYourPlan

                        billingCyclePicker
                    }
                    .padding(.bottom, DS.Spacing.standard)
                    .padding(.horizontal, DS.Spacing.large)
                    .background(BlurredBackground(fallbackBackgroundColor: DS.Color.Background.norm))
                }
            }
        }
        .background(DS.Color.BackgroundInverted.norm)
        .interactiveDismissDisabled()
    }

    private var planTiles: some View {
        VStack(spacing: DS.Spacing.large) {
            ForEach(model.visiblePlanTiles) { planTileModel in
                PlanTile(model: planTileModel) { storeKitProductID in
                    await model.onGetPlanTapped(
                        storeKitProductID: storeKitProductID,
                        toastStateStore: toastStateStore,
                        dismiss: dismiss.callAsFunction
                    )
                }
            }
        }
    }

    private var chooseYourPlan: some View {
        Text(L10n.chooseYourPlan)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundStyle(DS.Color.Text.norm)
            .padding(.vertical, 11)
    }

    private var billingCyclePicker: some View {
        Picker("".notLocalized, selection: $model.selectedCycle) {
            ForEach(model.availableCycles, id: \.self) { cycle in
                Text(model.label(for: cycle))
                    .tag(cycle)
            }
        }
        .pickerStyle(.segmented)
    }

    public init(model: OnboardingUpsellScreenModel) {
        self.model = model
    }
}

#Preview {
    Color
        .clear
        .sheet(isPresented: .constant(true)) {
            OnboardingUpsellScreen(model: .preview)
        }
        .environmentObject(ToastStateStore(initialState: .initial))
}
