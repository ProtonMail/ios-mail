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

/**
 This wrapper is to fix an issue with the native `.onSubmit` modifier which retains the callback
 causing a retain cycle.

 Inside the `onSubmit` closure, any reference to annottated SwiftUI variables
 like @State, @StateObject, @Binding, ... will be retained and won't be deallocated even when
 the keyboard is dismissed.

 The current solution uses a wrapper class informed with the relevant data to be referenced as weak
 in the capture list of the native `.onSubmit` modifier.
 */
struct OnSearchSubmitWrapper: ViewModifier {
    final class CallbackWrapper {
        var query: String
        var onQuerySubmmitted: ((String) -> Void)?

        init(query: String) {
            self.query = query
        }
    }

    @State var wrapper: CallbackWrapper
    @Binding var query: String
    let onQuerySubmmitted: (String) -> Void

    init(query: Binding<String>, onQuerySubmmitted: @escaping (String) -> Void) {
        self.wrapper = .init(query: query.wrappedValue)
        self._query = query
        self.onQuerySubmmitted = onQuerySubmmitted
    }

    func body(content: Content) -> some View {
        content
            .onSubmit { [weak wrapper] in
                wrapper?.onQuerySubmmitted?(wrapper!.query)
            }
            .onChange(of: query) {
                wrapper.query = query
            }
            .onLoad {
                wrapper.onQuerySubmmitted = onQuerySubmmitted
            }
    }
}

extension View {
    func onSubmitWrapper(query: Binding<String>, onQuerySubmmitted: @escaping (String) -> Void) -> some View {
        modifier(OnSearchSubmitWrapper(query: query, onQuerySubmmitted: onQuerySubmmitted))
    }
}
