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
import proton_mail_uniffi

/**
 Source of truth for custom labels that are applicable to Mailbox messages or conversations
 */
final class CustomLabelModel: ObservableObject {
    private let _labelsPublisher: CurrentValueSubject<[LocalLabel], Never> = .init([])
    var labelsPublisher: AnyPublisher<[LocalLabel], Never> {
        _labelsPublisher.eraseToAnyPublisher()
    }
    private let dependencies: Dependencies

    init(dependencies: Dependencies = .init()) {
        self.dependencies = dependencies
    }

    func fetchLabels() async {
        do {
            guard let userSession = try await dependencies.appContext.userContextForActiveSession() else { return }
            let applicableLabels = try userSession.applicableLabels()
            _labelsPublisher.value = applicableLabels
        } catch {
            AppLogger.log(error: error)
        }
    }
}

extension CustomLabelModel {

    struct Dependencies {
        let appContext: AppContext = .shared
    }
}
