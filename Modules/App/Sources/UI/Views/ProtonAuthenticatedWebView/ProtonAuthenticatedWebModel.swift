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

import Foundation
import InboxCore
import InboxIAP
import proton_app_uniffi

import enum SwiftUI.ColorScheme

@MainActor
final class ProtonAuthenticatedWebModel: NSObject, ObservableObject {
    @Published private(set) var state: State
    @Published var presentedUpsell: UpsellScreenModel?
    private let webViewPage: ProtonAuthenticatedWebPage
    private let dependencies: Dependencies
    let upsellCoordinator: UpsellCoordinator?

    init(
        webViewPage: ProtonAuthenticatedWebPage,
        dependencies: Dependencies = .init(),
        upsellCoordinator: UpsellCoordinator?
    ) {
        self.webViewPage = webViewPage
        self.state = .forkingSession
        self.dependencies = dependencies
        self.upsellCoordinator = upsellCoordinator
    }

    func generateSubscriptionUrl(colorScheme: ColorScheme) {
        guard let userSession = dependencies.appContext.sessionState.userSession else { return }

        let domain = ApiConfig.current.envId.domain
        let appDetails = AppDetails.mail
        let appVersion = appDetails.backendFacingVersion

        Task {
            updateState(.forkingSession)
            switch await userSession.fork(platform: appDetails.platform, product: appDetails.product) {
            case .ok(let selectorToken):
                let theme = colorScheme == .light ? "0" : "1"
                let url = webPageUrl(domain: domain, appVersion: appVersion, theme: theme, selector: selectorToken)
                updateState(.urlReady(url: url))
            case .error(let error):
                AppLogger.log(error: error)
                updateState(.error(error))
            }
        }
    }

    func pollEvents() {
        guard let userSession = dependencies.appContext.sessionState.userSession else {
            AppLogger.log(message: "poll events called but no active session found", category: .userSessions)
            return
        }

        Task {
            do {
                AppLogger.log(message: "poll events", category: .rustLibrary)
                try await userSession.forceEventLoopPoll().get()
            } catch {
                AppLogger.log(error: error, category: .rustLibrary)
            }
        }
    }

    private func updateState(_ newState: State) {
        state = newState
    }

    private func webPageUrl(domain: String, appVersion: String, theme: String, selector: String) -> URL {
        let params = "?action=\(webViewPage.action)&app-version=\(appVersion)&theme=\(theme)#selector=\(selector)"
        return URL(string: "https://account.\(domain)/lite\(params)")!
    }
}

extension ProtonAuthenticatedWebModel {
    enum State {
        case forkingSession
        case urlReady(url: URL)
        case error(Error)
    }
}

extension ProtonAuthenticatedWebModel {
    struct Dependencies {
        let appContext: AppContext

        init(appContext: AppContext = .shared) {
            self.appContext = appContext
        }
    }
}

enum ProtonAuthenticatedWebPage: Int, Identifiable {
    case accountSettings
    case addressSignatures
    case emailSettings
    case spamFiltersSettings
    case privacySecuritySettings
    case createFolderOrLabel

    var action: String {
        switch self {
        case .accountSettings:
            "account-settings"
        case .addressSignatures:
            "email-signatures"
        case .emailSettings:
            "email-settings"
        case .spamFiltersSettings:
            "spam-filters-settings"
        case .createFolderOrLabel:
            "labels-settings"
        case .privacySecuritySettings:
            "privacy-security-settings"
        }
    }

    // MARK: - Identifiable

    var id: Int {
        rawValue
    }
}
