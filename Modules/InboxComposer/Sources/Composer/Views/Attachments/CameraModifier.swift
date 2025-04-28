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

private struct CameraModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onPhotoTaken: (UIImage) async -> Void

    func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                CameraView() { image in
                    Task { await onPhotoTaken(image) }
                }
                .edgesIgnoringSafeArea(.all)
            }
    }
}

extension View {
    func camera(isPresented: Binding<Bool>, onPhotoTaken: @escaping (UIImage) async -> Void) -> some View {
        modifier(CameraModifier(isPresented: isPresented, onPhotoTaken: onPhotoTaken))
    }
}
