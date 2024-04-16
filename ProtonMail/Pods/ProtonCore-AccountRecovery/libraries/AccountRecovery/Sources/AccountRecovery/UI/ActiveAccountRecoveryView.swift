//
//  Created on 4/7/23.
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

/// View shown for the Grace period state of the **Account Recovery** process
public struct ActiveAccountRecoveryView: View {

    @ObservedObject var viewModel: AccountRecoveryView.ViewModel
    @State var isAnimating: Bool = false

    public var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(alignment: .top, spacing: 10) {
                IconProvider.exclamationCircle
                Text(passwordResetReceivedL10nStringKey,
                     bundle: AccountRecoveryModule.resourceBundle,
                     comment: "In Active Account Recovery state screen (the grace period), Request received intro. Variable is an email, interpolated at %@, with ** delimiters for bold type (we have a replica without delimiters for older iOS versions).")
                .frame(maxWidth: .infinity, alignment: .leading)

            }
            HStack(spacing: 12) {
                Image(AccountRecoveryConstants.ImageNames.passwordResetLockClock,
                      bundle: AccountRecoveryModule.resourceBundle)
                VStack(alignment: .leading) {
                    Text("Password reset requested",
                         bundle: AccountRecoveryModule.resourceBundle,
                         comment: "In Active Account Recovery state screen, heading for password reset requested callout.")
                    .font(.system(size: 17))
                        .foregroundColor(ColorProvider.TextNorm)
                    Text("You can change your password in \(viewModel.remainingTime.asRemainingTimeStringAndDate()).",
                         bundle: AccountRecoveryModule.resourceBundle,
                         comment: "In Active Account Recovery state screen, text explaining how long remaining, and also date, before being able to change the password. Both values are interpolated as a single string at %@.")
                }
            }
            .padding(12)
            .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/)
            .background(ColorProvider.BackgroundSecondary)
            .cornerRadius(12)

            Text("To make sure it's really you trying to reset your password, we wait 72 hours before approving requests.",
                 bundle: AccountRecoveryModule.resourceBundle,
                 comment: "In Active Account Recovery state screen, explain why the user has to wait 72h before being able to change the password."
            )

            Text(callToActionIfUnexpectedL10nStringKey,
                 bundle: AccountRecoveryModule.resourceBundle,
                 comment: "In Active Account Recovery state screen, advice in case the reset is unexpected for the user. The call to action is delimited with ** for bold type (we have a replica without delimiters for older iOS versions).")

            Button {
                isAnimating.toggle()
                Task { @MainActor in
                    await viewModel.cancelPressed()
                    isAnimating.toggle()
                }
            } label: {
                ZStack(alignment: .trailing) {
                    Text(ARTranslation.graceViewCancelButtonCTA.l10n)
                        .frame(maxWidth: .infinity)

                    if isAnimating {
                        ProgressView()
                            .padding(.trailing, 16)
                    }
                }.frame(minWidth: 0,
                        maxWidth: .infinity,
                        minHeight: 48)
            }
            .buttonStyle(SolidButton())
            .padding(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
            Spacer()

        }
        .font(.system(size: 14))
        .foregroundColor(ColorProvider.TextWeak)
        .padding(16)
        .background(ColorProvider.BackgroundNorm)
        .frame(maxHeight: .infinity)
        .navigationTitle(ARTranslation.graceViewTitle.l10n)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            ObservabilityEnv.report(.accountRecoveryScreenView(screenID: .gracePeriodInfo))
        }
    }

    var passwordResetReceivedL10nStringKey: LocalizedStringKey {
        var value = "We received a password reset request for **\(viewModel.email)**."
        if #unavailable(iOS 15) {
            value = value
                .replacingOccurrences(of: "**", with: "")
        }
        return LocalizedStringKey(value)
    }

    var callToActionIfUnexpectedL10nStringKey: LocalizedStringKey {
        var value = "If you didn't ask to reset your password, **cancel this request now**."
        if #unavailable(iOS 15) {
            value = value
                .replacingOccurrences(of: "**", with: "")
        }
        return LocalizedStringKey(value)
    }

    public init(viewModel: AccountRecoveryView.ViewModel) {
        _viewModel = ObservedObject(wrappedValue: viewModel)
    }

    private func makeKeyDroppingMarkdownIfNeeded(_ value: String) -> LocalizedStringKey {
        LocalizedStringKey(value)
    }
}

#if DEBUG
struct ActiveAccountRecoveryView_Previews: PreviewProvider {
    static var viewModel = {
        let vm = AccountRecoveryView.ViewModel()
        vm.email = "norbert@example.com"
        vm.remainingTime = 3600 * 72
        vm.state = .grace
        return vm
    }()

    static var previews: some View {
        ActiveAccountRecoveryView(viewModel: Self.viewModel)
    }
}
#endif
#endif
