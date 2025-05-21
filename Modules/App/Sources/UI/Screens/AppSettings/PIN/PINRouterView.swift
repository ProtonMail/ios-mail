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
import SwiftUI

struct PINRouterView: View {
    private let type: PINScreenType
    @StateObject var router: Router<PINRoute>
    @Environment(\.dismiss) var dismiss

    init(type: PINScreenType) {
        self.type = type
        self._router = .init(wrappedValue: .init())
    }

    var body: some View {
        NavigationStack(path: navigationPath) {
            PINScreen(type: type, dismiss: { dismiss.callAsFunction() })
                .navigationDestination(for: PINRoute.self) { route in
                    view(route: route)
                        .navigationBarBackButtonHidden()
                }
        }.environmentObject(router)
    }

    private var navigationPath: Binding<[PINRoute]> {
        .init(
            get: { router.stack },
            set: { router.stack = $0 }
        )
    }

    @MainActor @ViewBuilder
    private func view(route: PINRoute) -> some View {
        switch route {
        case .pin(let type):
            PINScreen(type: type, dismiss: { dismiss.callAsFunction() })
        }
    }
}
