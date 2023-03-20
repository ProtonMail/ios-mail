// Copyright (c) 2023 Proton Technologies AG
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
import StoreKit

// sourcery: mock
protocol AppRatingManagerProtocol {
    func requestAppRating()
    func openAppStoreToReviewApp()
}

struct AppRatingManager: AppRatingManagerProtocol {
    static let shared = AppRatingManager()

    private init() {}

    /// Shows a native in-app alert to ask the user to rate the app
    func requestAppRating() {
        if #available(iOS 14.0, *), let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    /// Navigates to Proton Mail's app store page where the user can review the app with a written comment
    func openAppStoreToReviewApp() {
        let appStoreScheme = URL.protonMailAppStoreUrlScheme
        let queryToWriteReview: URLQueryItem = .init(name: "action", value: "write-review")
        guard var urlComponents = URLComponents(url: appStoreScheme, resolvingAgainstBaseURL: false) else {
            assertionFailure()
            return
        }
        urlComponents.queryItems = [queryToWriteReview]
        guard let urlSchemeToWriteReview = urlComponents.url else {
            assertionFailure()
            return
        }
        UIApplication.shared.open(urlSchemeToWriteReview)
    }
}
