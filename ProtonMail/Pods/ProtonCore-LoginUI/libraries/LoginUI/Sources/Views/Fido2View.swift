//
//  Fido2View.swift
//  ProtonCore-Login - Created on 30/04/2024.
//
//  Copyright (c) 2024 Proton AG
//
//  This file is part of Proton AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

#if os(iOS)

import SwiftUI
import ProtonCoreUIFoundations

@available(iOS 15.0, *)
public struct Fido2View: View {
    @ObservedObject var viewModel: ViewModel

    var isNested: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Group {
                Text("Present a security key linked to your Proton Account.",
                     bundle: LUITranslation.bundle,
                     comment: "FIDO2 Key prompt")
                Link(destination: URL(string: "https://proton.me/support/two-factor-authentication-2fa")!) {
                    Text("Learn more",
                         bundle: LUITranslation.bundle,
                         comment: "Link text to the Proton KB explaining 2FA")
                }
            }
            .font(isNested ? .body : .title3)

            Image("physical-key",
                  bundle: LoginUIModule.resourceBundle)
            .frame(maxWidth: .infinity, alignment: .center)

            PCButton(
                style: .constant(.init(mode: .solid)),
                content: .constant(.init(
                    title: "Authenticate",
                    isEnabled: !viewModel.isLoading,
                    isAnimating: viewModel.isLoading,
                    action: { viewModel.startSignature() })
                )
            )
        }
        .frame(maxWidth: .infinity,
               maxHeight: .infinity,
               alignment: .top)

    }
}

#if DEBUG
#Preview {
    if #available(iOS 15.0, *) {
        return Fido2View(viewModel: Fido2View.ViewModel.initial)
            .padding(20)
    } else {
        return Text("🦖 This view is not available for iOS versions < 15.0")
    }
}
#endif

#endif
