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

@testable import ProtonMail

class StarActionPerformerActionsSpy {
    private(set) var invokedStarMessage: [ID] = []
    private(set) var invokedStarConversation: [ID] = []
    private(set) var invokedUnstarMessage: [ID] = []
    private(set) var invokedUnstarConversation: [ID] = []

    private(set) lazy var testingInstance = StarActionPerformerActions(
        starMessage: { [weak self] _, messagesIDs in
            self?.invokedStarMessage = messagesIDs
            return .ok
        },
        starConversation: { [weak self] _, conversationsIDs in
            self?.invokedStarConversation = conversationsIDs
            return .ok
        },
        unstarMessage: { [weak self] _, messagesIDs in
            self?.invokedUnstarMessage = messagesIDs
            return .ok
        },
        unstarConversation: { [weak self] _, conversationsIDs in
            self?.invokedUnstarConversation = conversationsIDs
            return .ok
        }
    )
}
