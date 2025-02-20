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

struct MessageBannersView: View {
    let model: [MessageBanner]
    
    init(model: [MessageBanner]) {
        self.model = model
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(model, id: \.id) { banner in
                MessageBannerView(model: banner)
            }
        }
    }
}

#Preview {
    MessageBannersView(model: [
        .init(
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            button: nil,
            style: .regular
        ),
        .init(
            message: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            button: nil,
            style: .error
        ),
        .init(
            message: "Lorem ipsum dolor sit amet",
            button: .init(title: "Action", action: {}),
            style: .regular
        ),
        .init(
            message: "Lorem ipsum dolor sit amet",
            button: .init(title: "Action", action: {}),
            style: .error
        ),
        .init(
            message: "Lorem ipsum dolor sit amet",
            button: nil,
            style: .regular
        ),
        .init(
            message: "Lorem ipsum dolor sit amet",
            button: nil,
            style: .error
        )
    ])
}

