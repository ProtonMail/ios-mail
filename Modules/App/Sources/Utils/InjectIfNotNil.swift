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

struct InjectIfNotNil<T: ObservableObject>: ViewModifier {
    var object: T?

    func body(content: Content) -> some View {
        if let object = object {
            content.environmentObject(object)
        } else {
            content
        }
    }
}

extension View {
    func injectIfNotNil<T: ObservableObject>(_ object: T?) -> some View {
        self.modifier(InjectIfNotNil(object: object))
    }
}
