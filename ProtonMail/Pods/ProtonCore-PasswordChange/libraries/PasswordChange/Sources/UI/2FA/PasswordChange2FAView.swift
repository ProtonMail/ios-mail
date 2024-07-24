//
//  PasswordChange2FAView.swift
//  ProtonCore-PasswordChange - Created on 27.03.2024.
//
//  Copyright (c) 2024 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
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
import ProtonCoreObservability
import ProtonCoreServices

struct PasswordChange2FAView: View {
    @ObservedObject public var viewModel: ViewModel

    @State var authenticateButtonIsEnabled = false

    /// Constructor taking a view model and where to connect it to
    /// - Parameter viewModel: The ViewModel that holds the data for this view
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                PCTextField(
                    style: .constant(.init(mode: .idle)),
                    content: $viewModel.tfaFieldContent
                )

                PCButton(
                    style: .constant(.init(mode: .solid)),
                    content: .constant(.init(
                        title: PCTranslation.authenticate.l10n,
                        isEnabled: authenticateButtonIsEnabled,
                        isAnimating: viewModel.authenticateIsLoading,
                        action: { viewModel.authenticateTapped() })
                    )
                )
            }
            .padding()
            .frame(maxHeight: .infinity)
            .keyboardDismissible()
            .navigationTitle(PCTranslation.tfaTitle.l10n)
            .navigationBarTitleDisplayMode(.inline)
        }
        .bannerDisplayable(bannerState: $viewModel.bannerState, configuration: .default())
        .onChange(of: viewModel.tfaFieldContent.text) { _ in
            authenticateButtonIsEnabled = !viewModel.tfaFieldContent.text.isEmpty
        }
        .onAppear {
            viewModel.tfaFieldContent.focus()
            ObservabilityEnv.report(.screenLoadCountTotal(screenName: .changePassword2FA))
        }
    }
}

struct PasswordChange2FAView_Previews: PreviewProvider {

    static var viewModel = {
        return PasswordChange2FAView.ViewModel(
            mode: .loginPassword,
            twoFA: AuthInfoResponse.TwoFA(enabled: .both),
            loginPassword: "",
            newPassword: "",
            passwordChangeCompletion: nil
        )
    }()

    static var previews: some View {
        PasswordChange2FAView(viewModel: Self.viewModel)
    }
}

#endif
