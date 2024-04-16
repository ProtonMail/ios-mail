//
//  CancelledAccountRecoveryView.swift
//  Pods - Created on 13/7/23.
//
//  Copyright (c) 2023 Proton AG
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
import ProtonCoreObservability

public struct CancelledAccountRecoveryView: View {

    @ObservedObject var viewModel: AccountRecoveryView.ViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(AccountRecoveryConstants.ImageNames.passwordResetLockExclamation,
                      bundle: AccountRecoveryModule.resourceBundle)
                VStack(alignment: .leading) {
                    Text("Password reset cancelled",
                         bundle: AccountRecoveryModule.resourceBundle,
                         comment: "In Cancelled Account Recovery state screen. Reset cancelled heading.")
                    .frame(alignment: .leading)
                    .font(.system(size: 17))
                    .foregroundColor(ColorProvider.TextNorm)
                    Text(LocalizedStringKey(viewModel.reason.localizableDescription),
                         bundle: AccountRecoveryModule.resourceBundle,
                         comment: "In Cancelled Account Recovery state screen. Reason for cancellation."
                    )
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(12)
            .background(ColorProvider.BackgroundSecondary)
            .cornerRadius(12)

            Text(changePasswordAdviceL10nStrongKey,
                 bundle: AccountRecoveryModule.resourceBundle,
                 comment: "In Cancelled Account Recovery state screen. Advice the user to change password. The call to action is surrounded in bold delimiters (**), with a replica without them for older iOS versions."
            )
            .frame(maxWidth: .infinity)

            Spacer()
        }
        .font(.system(size: 14))
        .foregroundColor(ColorProvider.TextWeak)
        .padding(16)
        .background(ColorProvider.BackgroundNorm)
        .frame(maxHeight: .infinity)
        .navigationTitle(ARTranslation.cancelledViewTitle.l10n)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear() {
            ObservabilityEnv.report(.accountRecoveryScreenView(screenID: .recoveryCancelledInfo))
        }
    }

    var changePasswordAdviceL10nStrongKey: LocalizedStringKey {
        var value = """
If you never made a password reset request, someone else could have access to your account. **Change your password now**.
"""
        if #unavailable(iOS 15) {
            value = value
                .replacingOccurrences(of: "**", with: "")
        }
        return LocalizedStringKey(value)
    }
}

struct CancelledAccountRecoveryView_Previews: PreviewProvider {
    static var viewModel = {
        let vm = AccountRecoveryView.ViewModel()
        vm.email = "norbert@example.com"
        vm.remainingTime = 3600 * 72
        vm.state = .cancelled
        vm.reason = .authentication
        return vm
    }()

    static var previews: some View {
        CancelledAccountRecoveryView(viewModel: Self.viewModel)
    }
}
#endif
