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

import SwiftUI

/// dummy sign in screen to be able to start a rust session
struct SignIn: View {
    @EnvironmentObject var appState: AppState

    @State private var email: String = ""
    @State private var password: String = ""

    private let screenModel: SignInScreenModel = .init()

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(alignment: .leading, spacing: 11) {
                Text("Email")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.secondary)
                    .frame(height: 15, alignment: .leading)

                TextField("", text: $email)
                    .foregroundColor(.primary)
                    .frame(height: 44)
                    .padding(.horizontal, 12)
                    .background(Color.white)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
            }

            VStack(alignment: .leading, spacing: 11) {
                Text("Password")
                    .font(.system(size: 13, weight: .light))
                    .foregroundColor(.secondary)
                    .frame(height: 15, alignment: .leading)

                SecureField("", text: $password)
                    .frame(height: 44)
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .background(Color.white)
            }

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
                    Text("Sign In")
                        .foregroundColor(.white)
                        .frame(width: 215, height: 44, alignment: .center)
                }
                .background(.secondary)
                .cornerRadius(4)
                .padding(.top, 36)
                .alert(screenModel.errorMessage, isPresented: screenModel.isErrorPresented) {
                    Button("OK") {
                        screenModel.showError = false
                    }
                }
            }

            Spacer()
        }
        .padding()
        .background(.secondary.opacity(0.1))
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
