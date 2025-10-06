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
import OrderedCollections
import SwiftUI

public struct BannersView: View {
    let model: OrderedSet<Banner>

    public init(model: OrderedSet<Banner>) {
        self.model = model
    }

    public var body: some View {
        VStack(spacing: DS.Spacing.standard) {
            ForEach(model, id: \.id) { banner in
                BannerView(model: banner)
            }
        }
        .padding(.top, DS.Spacing.standard)
    }
}

#Preview {
    BannersView(model: [
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            subtitle: nil,
            size: .small(nil),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            subtitle: nil,
            size: .small(nil),
            style: .error
        ),
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet",
            subtitle: nil,
            size: .small(.button(.init(title: "Action", action: {}))),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet",
            subtitle: nil,
            size: .small(.button(.init(title: "Action", action: {}))),
            style: .error
        ),
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet",
            subtitle: nil,
            size: .small(nil),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            title: "Lorem ipsum dolor sit amet",
            subtitle: nil,
            size: .small(nil),
            style: .error
        ),
    ])
}
