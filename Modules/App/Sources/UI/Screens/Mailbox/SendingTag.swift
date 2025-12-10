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

struct SendingTag: View {
    let variant: Variant

    enum Variant: CaseIterable {
        case sending
        case failure
    }

    struct Configuration {
        let title: LocalizedStringResource
        let icon: ImageResource
        let color: Color
    }

    var body: some View {
        HStack(alignment: .center, spacing: DS.Spacing.compact) {
            Image(variant.configuration.icon)
                .resizable()
                .square(size: 14)
                .foregroundStyle(variant.configuration.color)
            Text(variant.configuration.title)
                .foregroundStyle(variant.configuration.color)
                .font(.caption)
        }
        .padding(.horizontal, DS.Spacing.standard)
        .padding(.vertical, DS.Spacing.compact)
        .overlay {
            Capsule()
                .stroke(variant.configuration.color, lineWidth: 1)
        }
    }
}

#Preview {
    ZStack(
        alignment: .center,
        content: {
            VStack {
                SendingTag(variant: .sending)
                SendingTag(variant: .failure)
            }
        })
}

private extension SendingTag.Variant {
    var configuration: SendingTag.Configuration {
        switch self {
        case .sending:
            .init(title: L10n.Mailbox.Item.sending, icon: DS.Icon.icPaperPlane, color: DS.Color.Notification.success)
        case .failure:
            .init(
                title: L10n.Mailbox.Item.sendingFailure,
                icon: DS.Icon.icExclamationCircle,
                color: DS.Color.Notification.error
            )
        }
    }
}
