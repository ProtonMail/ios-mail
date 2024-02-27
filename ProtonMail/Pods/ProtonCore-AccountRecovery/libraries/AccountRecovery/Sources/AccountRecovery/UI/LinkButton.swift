//
//  LinkButton.swift
//  ProtonCore-AccountRecovery - Created on 9/1/24.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//
#if os(iOS)
import SwiftUI
import ProtonCoreUIFoundations

/// This style is used to represent a Link button
/// - Reference: (see Proton Mobile iOS design document)
public struct LinkButton: ButtonStyle {

    let interactionNorm: Color = ColorProvider.InteractionNorm

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 17))
            .foregroundColor(interactionNorm)
    }
}

#endif
