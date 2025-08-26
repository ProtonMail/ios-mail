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

private struct FileImporterModifier: ViewModifier {
    @Binding var isPresented: Bool
    var onCompletion: (Result<[URL], any Error>) -> Void

    func body(content: Content) -> some View {
        content
            .fileImporter(
                isPresented: $isPresented,
                allowedContentTypes: [.item],
                allowsMultipleSelection: true,
                onCompletion: onCompletion
            )
    }
}

extension View {
    func fileImporter(isPresented: Binding<Bool>, onCompletion: @escaping (Result<[URL], any Error>) async -> Void) -> some View {
        modifier(
            FileImporterModifier(
                isPresented: isPresented,
                onCompletion: { result in
                    Task { await onCompletion(result) }
                }))
    }
}
