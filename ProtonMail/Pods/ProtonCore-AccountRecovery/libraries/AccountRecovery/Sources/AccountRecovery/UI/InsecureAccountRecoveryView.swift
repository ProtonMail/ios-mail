//
//  Created on 13/7/23.
//
//  Copyright (c) 2023 Proton AG
//
//  ProtonVPN is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonVPN is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonVPN.  If not, see <https://www.gnu.org/licenses/>.
#if os(iOS)
import SwiftUI
import ProtonCoreUIFoundations
import ProtonCoreObservability

public struct InsecureAccountRecoveryView: View {

    @ObservedObject var viewModel: AccountRecoveryView.ViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading) {
                HStack {
                    Image(AccountRecoveryConstants.ImageNames.passwordResetLockCheck,
                          bundle: AccountRecoveryModule.resourceBundle
                    )
                    VStack(alignment: .leading) {
                        Text("You can now reset your password",
                             bundle: AccountRecoveryModule.resourceBundle,
                             comment: "Insecure state screen heading")
                            .foregroundColor(ColorProvider.TextNorm)
                        Text(dateLimitL10nStringKey,
                             bundle: AccountRecoveryModule.resourceBundle,
                             comment: "In insecure state screen, date limit for the reset, with the date interpolated at %@.")
                            .font(Font.system(size: 13))

                    }
                }
                HStack(spacing: 8) {
                    Image(uiImage: IconProvider.tv)
                        .renderingMode(.template)
                        .foregroundColor(ColorProvider.IconNorm)
                        .padding(12)
                    VStack(alignment: .leading) {
                        Text("Change device to continue",
                             bundle: AccountRecoveryModule.resourceBundle,
                             comment: "In insecure state screen, instructions for how to carry out the password reset.")
                            .foregroundColor(ColorProvider.TextNorm)
                        Text("To reset your password, go back to your active session on **the originating device**.",
                             bundle: AccountRecoveryModule.resourceBundle,
                             comment: "In insecure state screen, instructions for how to carry out the password reset. Part of it is formatted in **bold**")
                            .font(Font.system(size: 13))
                    }
                }
            }
            .padding(12)
            .background(ColorProvider.BackgroundSecondary)
            .cornerRadius(12)

            Text(timeRemainingAndInstructionsL10nStringKey,
                 bundle: AccountRecoveryModule.resourceBundle,
                 comment: "In insecure state screen, steps for resetting the password. Separated with new lines. The remaining time is interpolated at %@.")

            Button {
                Task { @MainActor in
                    await viewModel.cancelPressed()
                }
            } label: {
                Text(ARTranslation.insecureViewCancelButtonCTA.l10n)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(LinkButton())
            Spacer()
        }
        .font(Font.system(size: 14))
        .foregroundColor(ColorProvider.TextWeak)
        .padding(12)
        .background(ColorProvider.BackgroundNorm)
        .frame(maxWidth: .infinity)
        .navigationTitle(ARTranslation.insecureViewTitle.l10n)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            ObservabilityEnv.report(.accountRecoveryScreenView(screenID: .passwordChangeInfo))
        }
    }

    var timeRemainingAndInstructionsL10nStringKey: LocalizedStringKey {
        LocalizedStringKey("""
You have \(viewModel.remainingTime.asRemainingTimeString(allowingDays: true)) to reset your password.\n
You'll need to do this on the device and browser that you made your password reset request from.\n
If you didn't ask to reset your password, cancel the request now.
""")
    }

    var dateLimitL10nStringKey: LocalizedStringKey {
        LocalizedStringKey("Reset available until \(viewModel.remainingTime.asDateFromNow()).")
    }

    public init(viewModel: AccountRecoveryView.ViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }
}

struct InsecureAccountRecoveryView_Previews: PreviewProvider {
    static var viewModel = {
        let vm = AccountRecoveryView.ViewModel()
        vm.email = "norbert@example.com"
        vm.remainingTime = 3600 * 72
        vm.state = .insecure
        vm.isLoaded = true
        return vm
    }()

    static var previews: some View {
        InsecureAccountRecoveryView(viewModel: Self.viewModel)
    }
}
#endif
