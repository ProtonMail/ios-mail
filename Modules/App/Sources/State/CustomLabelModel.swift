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

import Combine
import Foundation
import proton_app_uniffi

/**
 Source of truth for custom labels that are applicable to Mailbox messages or conversations
 */
final class CustomLabelModel: ObservableObject {
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func fetchLabels() async -> [PMCustomLabel] {
        guard let userSession = dependencies.appContext.activeUserSession else { return [] }
        do {
            return try await userSession.applicableLabels()
        } catch {
            AppLogger.log(error: error)
            return []
        }
    }
}

extension CustomLabelModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
