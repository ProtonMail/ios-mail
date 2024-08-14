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
        guard let activeUser = dependencies.appContext.activeUserSession else { return }
        
        guard let appConfig = dependencies.appConfigService.appConfig else { return }
        let domain = appConfig.environment.domain
        let appVersion = appConfig.appVersion
        
        Task {
            await updateState(.forkingSession)
            do {
                let selectorToken = try await activeUser.fork()
                let theme = colorScheme == .light ? "0" : "1"
                let url = webPageUrl(domain: domain, appVersion: appVersion, theme: theme, selector: selectorToken)
                await updateState(.urlReady(url: url))
            } catch {
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
//        let params = "?action=\(webViewPage.action)&app-version=\(appVersion)&theme=\(theme)#selector=\(selector)"
        let params = "?action=\(webViewPage.action)&theme=\(theme)#selector=\(selector)" // TODO: put app-version back
        return URL(string:"https://account.\(domain)/lite\(params)")!
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
        let appConfigService: AppConfigService

        init(appContext: AppContext = .shared, appConfigService: AppConfigService = .shared) {
            self.appContext = appContext
            self.appConfigService = appConfigService
        }
    }
}

enum ProtonAuthenticatedWebPage: Int, Identifiable {
    case mailSettings
    case subscriptionDetails
    case createFolder
    case createLabel

    var action: String {
        switch self {
        case .mailSettings:
            "mail-settings"
        case .subscriptionDetails:
            "subscription-details"
        case .createFolder, .createLabel:
            "labels-settings"
        }
    }

    // MARK: - Identifiable

    var id: Int {
        rawValue
    }
}
