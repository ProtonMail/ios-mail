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

import DesignSystem
import SwiftUI

struct MailboxActionBarView: View {

    var body: some View {
            HStack(spacing: 48) {
                Button(action: {}, label: {
                    Image(uiImage: DS.Icon.icEnvelopeOpen)
                })
                Button(action: {}, label: {
                    Image(uiImage: DS.Icon.icArchiveBox)
                })
                Button(action: {}, label: {
                    Image(uiImage: DS.Icon.icTrash)
                })
                Button(action: {}, label: {
                    Image(uiImage: DS.Icon.icTag)
                })
                Button(action: {}, label: {
                    Image(uiImage: DS.Icon.icThreeDotsHorizontal)
                })
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(.thinMaterial)
            .compositingGroup()
            .shadow(radius: 2)
    }
}

#Preview {
    MailboxActionBarView()
}
