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

import InboxCore
import Foundation
import proton_app_uniffi
import enum SwiftUI.ColorScheme

final class ProtonAuthenticatedWebModel: @unchecked Sendable, ObservableObject {
    @Published private(set) var state: State
    private let webViewPage: ProtonAuthenticatedWebPage
    private let dependencies: Dependencies

    init(webViewPage: ProtonAuthenticatedWebPage, dependencies: Dependencies = .init()) {
        self.webViewPage = webViewPage
        self.state = .forkingSession
        self.dependencies = dependencies
    }

    func generateSubscriptionUrl(colorScheme: ColorScheme) {
        guard let userSession = dependencies.appContext.sessionState.userSession else { return }

        let apiConfig = ApiConfig.current
        let domain = apiConfig.envId.domain
        let appVersion = apiConfig.appVersion

        Task {
            await updateState(.forkingSession)
            switch await userSession.forkWithVersion(appVersion: "ios-mail") {
            case .ok(let selectorToken):
                let theme = colorScheme == .light ? "0" : "1"
                let url = webPageUrl(domain: domain, appVersion: appVersion, theme: theme, selector: selectorToken)
                await updateState(.urlReady(url: url))
            case .error(let error):
                AppLogger.log(error: error)
                await updateState(.error(error))
            }
        }
    }

    func pollEvents() {
        dependencies.appContext.pollEvents()
    }

    @MainActor
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
    case emailSettings
    case spamFiltersSettings
    case privacySecuritySettings
    case createFolderOrLabel

    var action: String {
        switch self {
        case .accountSettings:
            "account-settings"
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
