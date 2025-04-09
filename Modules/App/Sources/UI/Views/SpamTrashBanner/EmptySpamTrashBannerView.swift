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
    let state: EmptySpamTrashBanner
    
    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.medium) {
            HStack(alignment: .top, spacing: DS.Spacing.moderatelyLarge) {
                BannerIconTextView(icon: icon, text: title, style: .regular, lineLimit: .none)
            }
            .padding([.leading, .trailing], DS.Spacing.large)
            ForEachLast(collection: buttons) { type, isLast in
                VStack(spacing: DS.Spacing.medium) {
                    BannerButton(model: buttonModel(from: type), style: .regular, maxWidth: .infinity)
                        .padding([.leading, .trailing], DS.Spacing.large)
                    if !isLast {
                        DS.Color.Border.strong
                            .frame(height: 1)
                            .frame(maxWidth: .infinity)
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
            model = .init(title: "Upgrade to Auto-delete".notLocalized.stringResource) {
                // FIXME: Implement action
                print(">>> upgrade to auto-delete")
            }
        case .emptyLocation:
            model = .init(title: "Empty \(state.location.humanReadable) now".notLocalized.stringResource) {
                // FIXME: Implement action
                print(">>> Empty \(state.location.humanReadable) now")
            }
        }
        
        return model
    }
    
    private var title: String {
        switch state.userState {
        case .freePlan:
            "Upgrade to automatically remove emails that have been in Trash or Spam for over 30 days.".notLocalized
        case .paidAutoDeleteOn:
            "Messages in Trash and Spam will be automatically deleted after 30 days.".notLocalized
        case .paidAutoDeleteOff:
            "Auto-delete is turned off. Messages in trash and spam will remain until you delete them manually.".notLocalized
        }
    }
    
    private var icon: ImageResource {
        switch state.userState {
        case .freePlan, .paidAutoDeleteOn:
            DS.Icon.icTrashClock
        case .paidAutoDeleteOff:
            DS.Icon.icTrash
        }
    }
    
    private var buttons: [EmptySpamTrashBanner.ActionButton] {
        switch state.userState {
        case .freePlan:
            return [.upgradePlan, .emptyLocation]
        case .paidAutoDeleteOn:
            return [.emptyLocation]
        case .paidAutoDeleteOff:
            return [.emptyLocation]
        }
    }
}

#Preview {
    VStack(alignment: .center, spacing: 10) {
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .freePlan))
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .paidAutoDeleteOff))
        EmptySpamTrashBannerView(state: .init(location: .spam, userState: .paidAutoDeleteOff))
    }
}
