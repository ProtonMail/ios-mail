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

import SwiftUI

struct ComposerModalModifier: ViewModifier {
    @Binding var modalState: ComposerViewModalState?
    @Binding var modalAction: ComposerViewModalState?
    let modalFactory: ComposerViewModalFactory

    func body(content: Content) -> some View {
        content
            .sheet(item: $modalState, content: modalFactory.makeModal(for:))
            .onChange(of: modalAction) { _, newValue in
                if let newValue {
                    modalAction = nil
                    self.modalState = newValue
                }
            }
    }
}

extension View {
    func sheet(
        item: Binding<ComposerViewModalState?>,
        additionallyObserving modalAction: Binding<ComposerViewModalState?>,  // Change parameter
        content: ComposerViewModalFactory
    ) -> some View {
        modifier(
            ComposerModalModifier(
                modalState: item,
                modalAction: modalAction,
                modalFactory: content
            ))
    }
}
