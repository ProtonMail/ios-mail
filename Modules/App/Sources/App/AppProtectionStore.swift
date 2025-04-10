// Copyright (c) 2025 Proton Technologies AG
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

import Combine
import proton_app_uniffi

class AppProtectionStore {
    private let mailSession: () -> MailSession

    init(mailSession: @escaping () -> MailSession) {
        self.mailSession = mailSession
    }

    let protectionSubject: CurrentValueSubject<AppProtection, Never> = .init(.none)

    @MainActor
    func checkProtection() {
        Task {
            let protection = try! await mailSession().appProtection().get()
            protectionSubject.send(protection)
        }
    }

    func dismissLock() {
        protectionSubject.send(.none)
    }
}

extension AppProtection {

    var lockScreenType: LockScreenState.LockScreenType? {
        switch self {
        case .none:
            return nil
        case .biometrics:
            return .biometric
        case .pin:
            return .pin
        }
    }

}
