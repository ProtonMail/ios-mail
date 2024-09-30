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

import ProtonCoreUIFoundations
import SwiftUI

struct PartialOverlayActionSheet<Content: View>: View {
    typealias ContentBuilder = (_ dismissHandler: @escaping () -> Void) -> Content

    @Environment(\.presentationMode)
    private var presentationMode

    @State private var verticalOffset: CGFloat = 0

    private let contentBuilder: ContentBuilder
    private let cornerRadius = 20.0
    private let dragGestureDismissalThreshold = 100.0
    private let screenHeight: CGFloat

    @MainActor
    init(@ViewBuilder contentBuilder: @escaping ContentBuilder) {
        self.contentBuilder = contentBuilder
        screenHeight = UIScreen.main.bounds.height
    }

    var body: some View {
        VStack {
            Spacer()

            VStack(spacing: 0) {
                VStack {
                    Image(.grabber)
                }
                .frame(height: 20)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            withAnimation(.interactiveSpring) {
                                verticalOffset = max(0, value.translation.height)
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > dragGestureDismissalThreshold {
                                dismiss()
                            } else {
                                withAnimation {
                                    verticalOffset = 0
                                }
                            }
                        }
                )

                HStack {
                    CrossButton {
                        dismiss()
                    }
                    .padding(.leading, 8)
                    .padding(.top, -12)

                    Spacer()
                }

                contentBuilder(dismiss)
            }
            .background(ColorProvider.SidebarBackground)
            .colorScheme(.light)
            .padding(.bottom, cornerRadius)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .circular))
            .padding(.bottom, -cornerRadius)
            .offset(y: verticalOffset)
        }
        .ignoresSafeArea(edges: [.bottom])
        .onAppear {
            verticalOffset = screenHeight

            withAnimation {
                verticalOffset = 0
            }
        }
    }

    private func dismiss() {
        withAnimation(.easeInOut(duration: 0.25)) {
            verticalOffset = screenHeight
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            presentationMode.wrappedValue.dismiss()
        }
    }
}
