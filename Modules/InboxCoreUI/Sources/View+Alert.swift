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
import SwiftUI

extension View {
    public func alert(model: Binding<AlertViewModel?>) -> some View {
        modifier(AlertViewModifier(model: model))
    }
}

private struct AlertViewModifier: ViewModifier {
    @Binding private var model: AlertViewModel?

    init(model: Binding<AlertViewModel?>) {
        _model = model
    }

    func body(content: Content) -> some View {
        content.alert(
            model?.title.string ?? fallbackAlertTitle,
            isPresented: isPresented,
            presenting: model,
            actions: { alert in
                ForEach(alert.actions, id: \.title.string) { alertAction in
                    Button(alertAction.title.string, role: alertAction.buttonRole) {
                        alertAction.action()
                    }
                }
            },
            message: { alert in
                if let message = alert.message {
                    Text(message)
                }
            }
        )
    }

    // MARK: - Private

    /// The alert modifier in SwiftUI requires a non-optional title, even when there is no alert to display.
    /// Previously, we applied the modifier conditionally (based on model), but this caused unnecessary view re-renders.
    /// To prevent this, we now apply the alert modifier continuously, using an empty string (`fallbackAlertTitle`)
    /// as a placeholder when no alert is present, reducing redundant updates.
    private let fallbackAlertTitle = ""

    private var isPresented: Binding<Bool> {
        .readonly {
            model != nil
        }
    }
}
