// Copyright (c) 2025 Proton Technologies AG
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
import InboxCoreUI
import SwiftUI

extension AlertModel {

    static func reportBugDismissConfirmationAlert(
        action: @escaping (ReportBugDismissConfirmationAlertAction) -> Void
    ) -> Self {
        let actions: [AlertAction] = ReportBugDismissConfirmationAlertAction.allCases.map { actionType in
            .init(details: actionType, action: { action(actionType) })
        }

        return .init(
            title: L10n.ReportProblem.DismissConfirmationAlert.title,
            message: L10n.ReportProblem.DismissConfirmationAlert.message,
            actions: actions
        )
    }

}

enum ReportBugDismissConfirmationAlertAction: AlertActionInfo, CaseIterable {
    case cancel
    case close

    var info: (title: LocalizedStringResource, buttonRole: ButtonRole) {
        switch self {
        case .cancel:
            (CommonL10n.cancel, .cancel)
        case .close:
            (CommonL10n.close, .destructive)
        }
    }
}
