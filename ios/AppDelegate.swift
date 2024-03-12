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

final class AppDelegate: NSObject, UIApplicationDelegate {
    private let appDelegateManager = AppDelegateWrapper()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        return appDelegateManager.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}

import proton_mail_uniffi

struct AppDelegateWrapper {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]?
    ) -> Bool {
        do {
            try dependencies.appContext.start()

            return true

        } catch {
            print("❌ error launching the app \(error)")
            return false
        }
    }
}

extension AppDelegateWrapper {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}


//final class AppContext {
//    let appSession: AppSession
//
//    init() throws {
//        self.appSession = try AppSession()
//    }
//}



class Dummy {

    func start(email: String, password: String) async throws {
        print("email: \(email)")
        guard let applicationSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw AppSessionError.applicationSupportDirectoryNotAccessible
        }

        let applicationSupportPath = applicationSupport.path()

        // TODO: exclude application support from iCloud backup

        let mailContext = try MailContext(
            sessionDir: applicationSupportPath,
            userDir: applicationSupportPath,
            logDir: applicationSupportPath,
            logDebug: true,
            keyChain: Keychain.shared,
            networkCallback: NetworkStatusManager.shared
        )

        let flow = try mailContext.newLoginFlow(cb: SessionDelegate.shared)
        try await flow.login(email: email, password: password)

        // .isAwaiting2fa has a bug
        //        if flow.isAwaiting2fa() {
        //            print("❌ WAITING 2FA!")
        //            try await flow.submitTotp(code: "")
        //        }

        //        if flow.isLoggedIn() {
        //           let userContext = try flow.toUserContext() // flow object can now be discarded.
        //        }

        // For an existing session
        let sessions = try mailContext.storedSessions()

        guard let activeSession = sessions.first else {
            print("❌ No active session")
            return
        }
        let userContext = try mailContext.userContextFromSession(session: activeSession, cb: SessionDelegate.shared)

        try await userContext.initialize(cb: UserContextInitializationDelegate.shared)
        let mailbox = try Mailbox(ctx: userContext)
        let conversations = try mailbox.conversations(count: 50)

        print(conversations)
    }

}


enum AppSessionError: Error {
    case applicationSupportDirectoryNotAccessible
}

enum Keys: String {
    case session
}




