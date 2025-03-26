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

public struct AlertAction: Equatable {
    public let title: LocalizedStringResource
    public let buttonRole: ButtonRole
    public let action: () -> Void
    
    public init(title: LocalizedStringResource, buttonRole: ButtonRole, action: @escaping () -> Void) {
        self.title = title
        self.buttonRole = buttonRole
        self.action = action
    }
    
    public static func == (lhs: AlertAction, rhs: AlertAction) -> Bool {
        lhs.title == rhs.title && lhs.buttonRole == rhs.buttonRole
    }
}

public struct AlertViewModel: Equatable {
    public let title: LocalizedStringResource
    public let message: LocalizedStringResource?
    public let actions: [AlertAction]

    public init(title: LocalizedStringResource, message: LocalizedStringResource?, actions: [AlertAction]) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}
