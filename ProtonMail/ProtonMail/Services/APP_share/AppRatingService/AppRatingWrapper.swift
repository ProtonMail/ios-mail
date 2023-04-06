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

import StoreKit

// sourcery: mock
protocol AppRatingWrapper {
    func requestAppRating()
}

struct AppRatingManager: AppRatingWrapper {

    /// Shows a native in-app alert to ask the user to rate the app
    func requestAppRating() {
        guard !ProcessInfo.isRunningUITests else {
            // Disabled for ui tests to avoid unpredictable rating prompts
            return
        }
        #if !APP_EXTENSION
        if #available(iOS 14.0, *), let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        } else {
            SKStoreReviewController.requestReview()
        }
        #endif
    }
}
