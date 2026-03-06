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

import ProtonUIFoundations
import SwiftUI

public enum ButtonIcon {
    case asset(ImageResource)
    case sfSymbol(SFSymbol)
}

extension Button where Label == SwiftUI.Label<Text, Image> {
    public init(_ title: LocalizedStringResource, image: SFSymbol, action: @escaping () -> Void) {
        self.init(title, systemImage: image.rawValue, action: action)
    }

    public init(_ title: LocalizedStringResource, image: ButtonIcon, action: @escaping () -> Void) {
        switch image {
        case .asset(let imageResource):
            self.init(title, image: imageResource, action: action)
        case .sfSymbol(let symbol):
            self.init(title, image: symbol, action: action)
        }
    }
}
