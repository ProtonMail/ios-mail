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

import Combine
import Foundation
import proton_app_uniffi

// periphery:ignore:all - Avoid periphery to remove sendResultPublisher since it has to be retained
final class SendResultCoordinator: ObservableObject {
    private let sendResultPublisher: SendResultPublisher
    private var anyCancellables = Set<AnyCancellable>()

    let presenter: SendResultPresenter

    init(sendResultPublisher: SendResultPublisher, presenter: SendResultPresenter) {
        self.sendResultPublisher = sendResultPublisher
        self.presenter = presenter

        sendResultPublisher
            .results
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { value in Task { await presenter.presentResultInfo(value) } })
            .store(in: &anyCancellables)
    }

    @MainActor
    convenience init(userSession: MailUserSession, draftPresenter: DraftPresenter) {
        self.init(
            sendResultPublisher: SendResultPublisher(userSession: userSession),
            presenter: .init(draftPresenter: draftPresenter)
        )
    }
}
