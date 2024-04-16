//
//  PasswordChangeView.swift
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

public struct PasswordChangeView: View {
    @ObservedObject public var viewModel: ViewModel

    @State var saveButtonIsEnabled = false

    var textFieldContents: [String] {[
        viewModel.currentPasswordFieldContent.text,
        viewModel.newPasswordFieldContent.text,
        viewModel.confirmNewPasswordFieldContent.text
    ]}

    /// Constructor taking a view model and where to connect it to
    /// - Parameter viewModel: The ViewModel that holds the data for this view
    public init(viewModel: ViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                VStack(spacing: 30) {
                    Text(.init(PCTranslation.protonPasswordDescription.l10n))
                    .font(.subheadline)
                    .foregroundColor(ColorProvider.TextWeak)
                    .accentColor(ColorProvider.TextAccent)
                    PCTextField(
                        style: $viewModel.currentPasswordFieldStyle,
                        content: $viewModel.currentPasswordFieldContent
                    )

                    PCTextField(
                        style: $viewModel.newPasswordFieldStyle,
                        content: $viewModel.newPasswordFieldContent
                    )

                    PCTextField(
                        style: $viewModel.confirmNewPasswordFieldStyle,
                        content: $viewModel.confirmNewPasswordFieldContent
                    )
                }

                VStack {
                    PCButton(
                        style: .constant(.init(mode: .solid)),
                        content: .constant(.init(
                            title: PCTranslation.savePassword.l10n,
                            isEnabled: saveButtonIsEnabled,
                            isAnimating: viewModel.savePasswordIsLoading,
                            action: { viewModel.savePasswordTapped() }
                        ))
                    )
                }
            }
            .padding()
            .frame(maxHeight: .infinity)
            .keyboardDismissible()
            .navigationTitle(PCTranslation.accountPassword.l10n)
            .navigationBarTitleDisplayMode(.inline)
        }
        .bannerDisplayable(bannerState: $viewModel.bannerState, configuration: .default())
        .onChange(of: textFieldContents) { _ in
            saveButtonIsEnabled = textFieldContents.first(where: { $0.isEmpty }) == nil
        }
        .onAppear() {
            viewModel.currentPasswordFieldContent.focus()
            ObservabilityEnv.report(.screenLoadCountTotal(screenName: viewModel.screenLoadObservabilityEvent))
        }
    }
}

struct PasswordChangeView_Previews: PreviewProvider {

    static var viewModel = {
        return PasswordChangeView.ViewModel(mode: .loginPassword, passwordChangeCompletion: nil)
    }()

    static var previews: some View {
        PasswordChangeView(viewModel: Self.viewModel)
    }
}

#endif
