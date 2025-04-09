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
    private struct DisplayModel {
        let icon: ImageResource
        let title: String
        let buttons: [EmptySpamTrashBanner.ActionButton]
    }
    
    let state: EmptySpamTrashBanner
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            HStack(alignment: .top, spacing: DS.Spacing.moderatelyLarge) {
                BannerIconTextView(icon: displayModel.icon, text: displayModel.title, style: .regular, lineLimit: .none)
            }
            .horizontalPadding()
            ForEachLast(collection: displayModel.buttons) { type, isLast in
                VStack(spacing: DS.Spacing.medium) {
                    BannerButton(model: buttonModel(from: type), style: .regular, maxWidth: .infinity)
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
    }
    
    // MARK: - Private
    
    private func buttonModel(from type: EmptySpamTrashBanner.ActionButton) -> Banner.Button {
        let model: Banner.Button
        switch type {
        case .upgradePlan:
            model = .init(title: L10n.EmptySpamTrashBanner.upgradeAction) {
                // FIXME: Implement action
                print(">>> upgrade to auto-delete")
            }
        case .emptyLocation:
            model = .init(title: L10n.EmptySpamTrashBanner.emptyNowAction(location: state.location.humanReadable)) {
                // FIXME: Implement action
                print(">>> Empty \(state.location.humanReadable) now")
            }
        }
        
        return model
    }
    
    private var displayModel: DisplayModel {
        switch state.userState {
        case .freePlan:
            .init(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptySpamTrashBanner.freeUserTitle.string,
                buttons: [.upgradePlan, .emptyLocation]
            )
        case .paidAutoDeleteOn:
            .init(
                icon: DS.Icon.icTrashClock,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOnTitle.string,
                buttons: [.emptyLocation]
            )
        case .paidAutoDeleteOff:
            .init(
                icon: DS.Icon.icTrash,
                title: L10n.EmptySpamTrashBanner.paidUserAutoDeleteOffTitle.string,
                buttons: [.emptyLocation]
            )
        }
    }
}

private extension View {
    
    func horizontalPadding() -> some View {
        padding([.leading, .trailing], DS.Spacing.large)
    }
    
}

#Preview {
    VStack(alignment: .center, spacing: 10) {
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .freePlan))
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .paidAutoDeleteOff))
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .paidAutoDeleteOff))
        
        EmptySpamTrashBannerView(state: .init(location: .trash, userState: .freePlan))
        EmptySpamTrashBannerView(state: .init(location: .trash, userState: .paidAutoDeleteOff))
        EmptySpamTrashBannerView(state: .init(location: .trash, userState: .paidAutoDeleteOff))
    }
}
