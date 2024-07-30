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

import DesignSystem
import SwiftUI

/// dummy sign in screen to be able to start a rust session
struct SignIn: View {
    @State private var email: String = ""
    @State private var password: String = ""

    private let screenModel: SignInScreenModel = .init()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(alignment: .leading, spacing: 11) {
                Text("Email".notLocalized)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(DS.Color.Text.norm)
                    .frame(height: 15, alignment: .leading)

                TextField("".notLocalized, text: $email)
                    .foregroundColor(DS.Color.Text.norm)
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .background(DS.Color.Background.secondary)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .accessibilityIdentifier(SignInIdentifiers.emailField)
            }
            .accessibilityElement(children: .contain)

            VStack(alignment: .leading, spacing: 11) {
                Text("Password".notLocalized)
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(DS.Color.Text.norm)
                    .frame(height: 15, alignment: .leading)

                SecureField("".notLocalized, text: $password)
                    .frame(height: 44)
                    .foregroundColor(DS.Color.Text.norm)
                    .padding(.horizontal, 12)
                    .background(DS.Color.Background.secondary)
                    .accessibilityIdentifier(SignInIdentifiers.passwordField)
            }
            .accessibilityElement(children: .contain)

            if screenModel.isLoading {

                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
            } else {

                Button {
                    hideKeyboard()
                    Task {
                        await screenModel.login(email: email, password: password)
                    }
                } label: {
                    Text("Sign In".notLocalized)
                        .foregroundColor(DS.Color.Text.norm)
                        .frame(width: 215, height: 44, alignment: .center)
                }
                .background(DS.Color.Background.deep)
                .cornerRadius(4)
                .padding(.top, 36)
                .alert(screenModel.errorMessage, isPresented: screenModel.isErrorPresented) {
                    Button("OK".notLocalized) {
                        screenModel.showError = false
                    }
                }
                .accessibilityIdentifier(SignInIdentifiers.signInButton)
            }

            Spacer()
        }
        .padding()
        .background(DS.Color.Background.norm)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(SignInIdentifiers.rootItem)
    }
}

#if canImport(UIKit)
extension View {
    @MainActor
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
#endif

#Preview {
    SignIn()
}


private enum SignInIdentifiers {
    static let rootItem = "signIn.rootItem"
    static let emailField = "signIn.emailField"
    static let passwordField = "signIn.passwordField"
    static let signInButton = "signIn.signInButton"
}
