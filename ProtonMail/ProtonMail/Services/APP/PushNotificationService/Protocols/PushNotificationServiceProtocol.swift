// Copyright (c) 2022 Proton AG
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

import Foundation
import ProtonCore_Networking
import ProtonCore_Services

protocol PushNotificationServiceProtocol: AnyObject {
    func processCachedLaunchOptions()
}

protocol SessionIdProvider {
    var sessionIDs: [String] { get }
}

struct AuthCredentialSessionIDProvider: SessionIdProvider {
    var sessionIDs: [String] {
        return sharedServices.get(by: UsersManager.self).users.map { $0.authCredential.sessionID }
    }
}

// sourcery: mock
protocol SignInProvider {
    var isSignedIn: Bool { get }
}

struct SignInManagerProvider: SignInProvider {
    var isSignedIn: Bool {
        return sharedServices.get(by: UsersManager.self).hasUsers()
    }
}

// sourcery: mock
protocol UnlockProvider {
    var isUnlocked: Bool { get }
}

struct UnlockManagerProvider: UnlockProvider {
    var isUnlocked: Bool {
        return sharedServices.get(by: UnlockManager.self).isUnlocked()
    }
}
