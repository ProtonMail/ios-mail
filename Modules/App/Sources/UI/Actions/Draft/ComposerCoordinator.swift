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
import InboxComposer
import InboxCoreUI
import proton_app_uniffi
import ProtonUIFoundations
import SwiftUI

@MainActor
final class ComposerCoordinator: ObservableObject {
    enum ParentScreen {
        case home
        case search
    }

    @Published var parentScreen: ParentScreen = .home
    @Published fileprivate(set) var isPresentedInHome: Bool = false
    @Published fileprivate(set) var isPresentedInSearch: Bool = false
    private(set) var draftToPresent: DraftToPresent?
    let messageSent = PassthroughSubject<Void, Never>()

    private let sendResultPublisher: SendResultPublisher
    private let sendResultPresenter: SendResultPresenter
    private let draftSavedCoordinator: DraftSavedToastCoordinator
    private let toastStateStore: ToastStateStore
    private var anyCancellables = Set<AnyCancellable>()
    let userSession: MailUserSession
    let draftPresenter: DraftPresenter

    init(userSession: MailUserSession, toastStateStore: ToastStateStore) {
        self.userSession = userSession
        self.sendResultPublisher = SendResultPublisher(userSession: userSession)
        self.draftPresenter = DraftPresenter(
            userSession: userSession,
            draftProvider: .productionInstance,
            undoSendProvider: .productionInstance(userSession: userSession),
            undoScheduleSendProvider: .productionInstance(userSession: userSession)
        )
        self.sendResultPresenter = SendResultPresenter(draftPresenter: draftPresenter)
        self.draftSavedCoordinator = DraftSavedToastCoordinator(
            mailUSerSession: userSession,
            toastStoreState: toastStateStore
        )
        self.toastStateStore = toastStateStore
        setUpObservers()
    }

    func setUpObservers() {
        sendResultPublisher
            .results
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak sendResultPresenter] value in
                sendResultPresenter?.presentResultInfo(value)
            })
            .store(in: &anyCancellables)

        sendResultPresenter
            .toastAction
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak toastStateStore] action in
                switch action {
                case .present(let toast): toastStateStore?.present(toast: toast)
                case .dismiss(let toast): toastStateStore?.dismiss(toast: toast)
                }
            })
            .store(in: &anyCancellables)

        draftPresenter
            .draftToPresent
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] value in
                self?.showComposer(draftToPresent: value)
            })
            .store(in: &anyCancellables)
    }

    func showComposer(draftToPresent: DraftToPresent) {
        self.draftToPresent = draftToPresent
        switch parentScreen {
        case .home:
            isPresentedInHome = true
        case .search:
            isPresentedInSearch = true
        }
    }

    func onComposerDismiss(_ reason: ComposerDismissReason) {
        draftToPresent = nil
        switch reason {
        case .messageSent(let messageId), .messageScheduled(let messageId):
            guard let toastType = reason.sendResultToastType else { return }
            sendResultPresenter.presentResultInfo(.init(messageId: messageId, type: toastType))
            messageSent.send()
        case .dismissedManually(let savedDraftId):
            guard let savedDraftId else { return }
            draftSavedCoordinator.showDraftSavedToast(draftId: savedDraftId)
        case .draftDiscarded:
            toastStateStore.present(toast: .draftDiscarded())
        }
    }
}

// MARK: - ComposerModifier

struct ComposerModifier: ViewModifier {
    let screen: ComposerCoordinator.ParentScreen
    @ObservedObject var coordinator: ComposerCoordinator

    func body(content: Content) -> some View {
        content
            .onAppear {
                coordinator.parentScreen = screen
            }
            .onDisappear {
                if screen == .search {
                    coordinator.parentScreen = .home
                }
            }
            .adaptivePresentation(isPresented: bindingForMode()) {
                if let draftToPresent = coordinator.draftToPresent {
                    ComposerScreenFactory.makeComposer(
                        userSession: coordinator.userSession,
                        draftToPresent: draftToPresent,
                        onDismiss: coordinator.onComposerDismiss
                    )
                }
            }
    }

    private func bindingForMode() -> Binding<Bool> {
        switch screen {
        case .home:
            $coordinator.isPresentedInHome
        case .search:
            $coordinator.isPresentedInSearch
        }
    }
}

extension View {
    func composer(
        screen: ComposerCoordinator.ParentScreen,
        coordinator: ComposerCoordinator
    ) -> some View {
        modifier(ComposerModifier(screen: screen, coordinator: coordinator))
    }
}
