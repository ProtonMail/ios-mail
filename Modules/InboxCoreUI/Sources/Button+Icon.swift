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

import InboxCore
import InboxDesignSystem
import ProtonUIFoundations
import SwiftUI

public enum ButtonIcon {
    case asset(ImageResource)
    case sfSymbol(SFSymbol)
}

public enum ButtonFactory {
    public static func back(action: @escaping () -> Void) -> some View {
        Button(CommonL10n.back, image: SFSymbol.chevronLeft, action: action)
            .tint(DS.Color.Icon.norm)
    }

    @ViewBuilder
    public static func close(action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(CommonL10n.close, image: SFSymbol.xmark, action: action)
                .tint(DS.Color.Icon.norm)
        }
    }

    @ViewBuilder
    public static func cancel(action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(role: .cancel, action: action)
        } else {
            Button(CommonL10n.cancel, image: SFSymbol.xmark, action: action)
                .tint(DS.Color.Icon.norm)
        }
    }

    @ViewBuilder
    public static func save(action: @escaping () -> Void) -> some View {
        if #available(iOS 26, *) {
            Button(role: .confirm, action: action)
                .tint(DS.Color.InteractionBrand.norm)
        } else {
            Button(action: action) {
                Text(CommonL10n.save)
                    .fontWeight(.semibold)
                    .foregroundStyle(DS.Color.InteractionBrand.pressed)
            }
        }
    }
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
