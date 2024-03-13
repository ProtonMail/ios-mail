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

import proton_mail_uniffi
import SwiftUI

@Observable
final class SignInScreenModel {
    private let dependencies: Dependencies
    private(set) var isLoading = false
    private(set) var errorMessage: String = "" {
        didSet {
            showError = !errorMessage.isEmpty
        }
    }
    var showError: Bool = false

    var isErrorPresented: Binding<Bool> {
        Binding(get: {
            self.showError
        }, set: {
            self.showError = $0
        })
    }

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func login(email: String, password: String) async {
        isLoading = true
        do {
            try await dependencies.appContext.login(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

extension SignInScreenModel {

    struct Dependencies: Sendable {
        let appContext: AppContext = .shared
    }
}
