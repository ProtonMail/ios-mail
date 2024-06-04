//
//  TOTPView.swift
//  ProtonCore-Login - Created on 8/5/2024.
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

import Foundation
import SwiftUI
import ProtonCoreUIFoundations

struct TOTPView: View {

    @ObservedObject var viewModel: ViewModel

    var body: some View {
        VStack(spacing: 24) {
            PCTextField(
                style: .constant(.init(mode: .idle)),
                content: $viewModel.tfaFieldContent
            )

            PCButton(style: .constant(.init(mode: .solid)),
                     content: .constant(.init(title: LUITranslation.login_2fa_action_button_title.l10n,
                                              isEnabled: !viewModel.isLoading,
                                              isAnimating: viewModel.isLoading,
                                              action: { viewModel.startValidation() }
                                             )
                     )
            )
        }

    }

}

#if DEBUG
#Preview {
    TOTPView(viewModel: TOTPView.ViewModel(login: LoginStub()))
}
#endif

#endif
