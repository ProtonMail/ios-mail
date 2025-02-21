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

struct BannersView: View {
    let model: OrderedSet<Banner>
    
    init(model: OrderedSet<Banner>) {
        self.model = model
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(model, id: \.id) { banner in
                BannerView(model: banner)
            }
        }
    }
}

#Preview {
    BannersView(model: [
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            size: .small(nil),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            size: .small(nil),
            style: .error
        ),
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet",
            size: .small(.init(title: "Action", action: {})),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet",
            size: .small(.init(title: "Action", action: {})),
            style: .error
        ),
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet",
            size: .small(nil),
            style: .regular
        ),
        .init(
            icon: DS.Icon.icFire,
            message: "Lorem ipsum dolor sit amet",
            size: .small(nil),
            style: .error
        )
    ])
}

