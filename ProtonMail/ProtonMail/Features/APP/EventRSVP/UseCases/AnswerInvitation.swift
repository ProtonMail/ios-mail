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

import ProtonInboxRSVP

// sourcery: mock
protocol AnswerInvitation {
    func execute(parameters: AnswerInvitationWrapper.Parameters) async throws
}

/// This struct wraps the external AnswerInvitationUseCase to make it usable in Mail.
struct AnswerInvitationWrapper: AnswerInvitation {
    typealias Dependencies = AnyObject & AnswerInvitationUseCase.Dependencies

    private unowned let dependencies: Dependencies

    init(dependencies: Dependencies) {
        self.dependencies = dependencies
    }

    func execute(parameters: Parameters) async throws {
        guard let answeringContext = parameters.context else {
            return
        }

        let useCase = AnswerInvitationUseCase(dependencies: dependencies, answeringContext: answeringContext)

        try await useCase.execute(
            with: parameters.answer,
            for: answeringContext.event,
            calendar: answeringContext.calendarInfo,
            validatedContext: answeringContext.validated
        ).await()
    }
}

extension AnswerInvitationWrapper {
    struct Parameters {
        let answer: AttendeeStatusDisplay
        let context: AnsweringContext?
    }
}
