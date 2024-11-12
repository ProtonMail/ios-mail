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
    public func alert<AlertAction: AlertActionViewModel>(
        model: Binding<AlertViewModel<AlertAction>?>,
        handleAction: @escaping (AlertAction) -> Void
    ) -> some View {
        modifier(AlertViewModifier(model: model, handleAction: handleAction))
    }
}

struct AlertViewModifier<AlertAction: AlertActionViewModel>: ViewModifier {
    @Binding private var model: AlertViewModel<AlertAction>?
    private let handleAction: (AlertAction) -> Void

    init(model: Binding<AlertViewModel<AlertAction>?>, handleAction: @escaping (AlertAction) -> Void) {
        self._model = model
        self.handleAction = handleAction
    }

    func body(content: Content) -> some View {
        if let model {
            content.alert(
                model.title.string,
                isPresented: isPresented,
                presenting: model,
                actions: { model in
                    ForEach(model.actions, id: \.self) { action in
                        Button(action.title.string, role: action.buttonRole) {
                            handleAction(action)
                        }
                    }
                },
                message: { model in
                    if let message = model.message {
                        Text(message)
                    }
                }
            )
        } else {
            content
        }
    }

    // MARK: - Private

    private var isPresented: Binding<Bool> {
        .readonly {
            model != nil
        }
    }
}
