// Copyright (c) 2024 Proton Technologies AG
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

struct NoResultsView: View {
    @Environment(\.mainWindowSize) private var mainWindowSize: CGSize
    let variant: Variant

    var body: some View {
        VStack(spacing: DS.Spacing.extraLarge) {
            Spacer()

            Image(variant.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 128)

            VStack(spacing: DS.Spacing.mediumLight) {
                Text(variant.title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.Text.norm)

                Text(variant.body)
                    .font(.subheadline)
                    .foregroundStyle(DS.Color.Text.weak)
                    .multilineTextAlignment(.center)

                Spacer()
            }
            .padding(.horizontal, DS.Spacing.jumbo)
            .frame(maxHeight: mainWindowSize.height / 2)
        }
        .ignoresSafeArea(.keyboard)
    }
}

extension NoResultsView {
    enum Variant {
        case mailbox(isUnreadFilterOn: Bool)
        case search
        case outbox

        var image: ImageResource {
            switch self {
            case .mailbox: DS.Images.emptyMailbox
            case .search: DS.Images.searchNoResults
            case .outbox: DS.Images.emptyOutbox
            }
        }

        var title: LocalizedStringResource {
            switch self {
            case .mailbox(isUnreadFilterOn: true): L10n.Mailbox.EmptyState.titleForUnread
            case .mailbox(isUnreadFilterOn: false): L10n.Mailbox.EmptyState.title
            case .search: L10n.Search.noResultsTitle
            case .outbox: L10n.Mailbox.EmptyOutbox.title
            }
        }

        var body: LocalizedStringResource {
            switch self {
            case .mailbox: L10n.Mailbox.EmptyState.message
            case .search: L10n.Search.noResultsSubtitle
            case .outbox: L10n.Mailbox.EmptyOutbox.message
            }
        }
    }
}

#Preview("Empty mailbox") {
    NoResultsView(variant: .mailbox(isUnreadFilterOn: false))
        .environment(\.mainWindowSize, .init(width: 0, height: 750))
}

#Preview("Empty mailbox with unread only") {
    NoResultsView(variant: .mailbox(isUnreadFilterOn: true))
        .environment(\.mainWindowSize, .init(width: 0, height: 750))
}

#Preview("Empty search") {
    NoResultsView(variant: .search)
        .environment(\.mainWindowSize, .init(width: 0, height: 750))
}

#Preview("Empty outbox") {
    NoResultsView(variant: .outbox)
        .environment(\.mainWindowSize, .init(width: 0, height: 750))
}
