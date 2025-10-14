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

import InboxCore
import InboxDesignSystem
import SwiftUI

struct LoadingView<Content: View>: View {
    let dismiss: () -> Void
    let block: @MainActor () async throws -> Content

    @State private var content: Content?
    @State private var isFullyVisible = false
    @State private var shouldDismissOnceFullyVisible = false

    var body: some View {
        if let content {
            content
        } else {
            ZStack {
                DS.Color.Background.norm

                ProtonSpinner()
            }
            .onLoad {
                Task {
                    do {
                        content = try await block()
                    } catch {
                        AppLogger.log(error: error)
                        shouldDismissOnceFullyVisible = true
                    }
                }
            }
            .onDidAppear {
                isFullyVisible = true
            }
            .onChange(of: isFullyVisible, dismissIfNeeded)
            .onChange(of: shouldDismissOnceFullyVisible, dismissIfNeeded)
        }
    }

    private func dismissIfNeeded() {
        if isFullyVisible, shouldDismissOnceFullyVisible {
            dismiss()
        }
    }
}
