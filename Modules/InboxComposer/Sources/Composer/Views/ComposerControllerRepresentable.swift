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

import SwiftUI

struct ComposerControllerRepresentable: UIViewControllerRepresentable {
    let state: ComposerState
    let onEvent: (ComposerControllerEvent) -> Void

    func makeUIViewController(context: Context) -> ComposerController {
        ComposerController(state: state, onEvent: onEvent)
    }

    func updateUIViewController(_ controller: ComposerController, context: Context) {
        controller.state = state
    }

}

#Preview {
    struct Preview: View {
        
        var body: some View {
            VStack {
                ComposerControllerRepresentable(state: .init(recipients: [])) { event in
                    print(event)
                }
                .border(.yellow)

                Spacer()
            }
        }
    }

    return Preview()
}
