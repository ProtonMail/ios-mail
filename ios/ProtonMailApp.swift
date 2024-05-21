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

@main
struct ProtonMail: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    // declaration of state objects
    private let appUIState = AppUIState()
    private let userSettings = UserSettings(
        mailboxActions: .init()
    )
    private let customLabelModel = CustomLabelModel()

    var body: some Scene {
        WindowGroup {
            Root(appContext: .shared, appRoute: .shared, customLabelModel: customLabelModel)
                .environmentObject(appUIState)
                .environmentObject(userSettings)
        }
        .onChange(of: scenePhase, { oldValue, newValue in
            // scenePhase contains an aggregate phase for all scenes
            if newValue == .active {
                AppLifeCycle.shared.allScenesDidBecomeActive()
            } else if newValue == .background {
                AppLifeCycle.shared.allScenesDidEnterBackground()
            }
        })
    }
}

struct Root: View {
    @EnvironmentObject private var appUIState: AppUIState

    // The route determines the screen that will be rendered
    @ObservedObject private var appContext: AppContext
    @ObservedObject private var appRoute: AppRouteState
    @ObservedObject private var customLabelModel: CustomLabelModel

    init(
        appContext: AppContext,
        appRoute: AppRouteState,
        customLabelModel: CustomLabelModel
    ) {
        self.appContext = appContext
        self.appRoute = appRoute
        self.customLabelModel = customLabelModel
    }

    var body: some View {
        if let activerUser = appContext.activeUserSession {
            AuthenticatedScreens(appRoute: appRoute, customLabelModel: customLabelModel, userSession: activerUser)
        } else {
            SignIn()
        }
    }
}
