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

struct EmptySpamTrashBannerView: View {
    @EnvironmentObject var toastStateStore: ToastStateStore
    private let model: EmptySpamTrashBanner
    
    init(model: EmptySpamTrashBanner) {
        self.model = model
    }
    
    var body: some View {
        StoreView(
            store: EmptySpamTrashBannerStateStore(model: model, toastStateStore: toastStateStore)
        ) { state, store in
            VStack(alignment: .leading, spacing: DS.Spacing.medium) {
                HStack(alignment: .top, spacing: DS.Spacing.moderatelyLarge) {
                    BannerIconTextView(
                        icon: state.icon,
                        text: state.title,
                        style: .regular,
                        lineLimit: .none
                    )
                }
                .horizontalPadding()
                ForEachLast(collection: store.state.buttons) { type, isLast in
                    VStack(spacing: DS.Spacing.medium) {
                        BannerButton(model: buttonModel(from: type, store: store), style: .regular, maxWidth: .infinity)
                            .buttonStyle(.plain)
                            .horizontalPadding()
                        if !isLast {
                            DS.Color.Border.strong.frame(height: 1).frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding([.top, .bottom], DS.Spacing.medium)
            .background {
                RoundedRectangle(cornerRadius: DS.Radius.extraLarge)
                    .fill(DS.Color.Background.norm)
                    .stroke(DS.Color.Border.strong, lineWidth: 1)
            }
            .frame(maxWidth: .infinity)
            .alert(model: store.binding(\.alert))
        }
    }
    
    // MARK: - Private
    
    private func buttonModel(
        from type: EmptySpamTrashBanner.ActionButton,
        store: EmptySpamTrashBannerStateStore
    ) -> Banner.Button {
        let model: Banner.Button

        switch type {
        case .upgradePlan:
            model = .init(title: L10n.EmptySpamTrashBanner.upgradeAction) {
                store.handle(action: .upgradeToAutoDelete)
            }
        case .emptyLocation:
            let location = store.model.location.humanReadable.lowercased()
            
            model = .init(title: L10n.EmptySpamTrashBanner.emptyNowAction(location: location)) {
                store.handle(action: .emptyLocation)
            }
        }
        
        return model
    }
}

private extension View {
    
    func horizontalPadding() -> some View {
        padding([.leading, .trailing], DS.Spacing.large)
    }
    
}

#Preview {
    ScrollView {
        VStack(alignment: .center, spacing: 10) {
            EmptySpamTrashBannerView(model: .init(location: .spam, userState: .freePlan))
            EmptySpamTrashBannerView(model: .init(location: .spam, userState: .paidAutoDeleteOff))
            EmptySpamTrashBannerView(model: .init(location: .spam, userState: .paidAutoDeleteOff))
            
            EmptySpamTrashBannerView(model: .init(location: .trash, userState: .freePlan))
            EmptySpamTrashBannerView(model: .init(location: .trash, userState: .paidAutoDeleteOff))
            EmptySpamTrashBannerView(model: .init(location: .trash, userState: .paidAutoDeleteOff))
        }
        .padding([.leading, .trailing], DS.Spacing.large)
    }
}
