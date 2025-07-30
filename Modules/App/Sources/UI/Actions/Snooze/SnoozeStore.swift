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
import InboxIAP
import SwiftUI
import proton_app_uniffi

@MainActor
class SnoozeStore: StateStore {
    @Published var state: SnoozeState
    private let upsellScreenPresenter: UpsellScreenPresenter
    private let toastStateStore: ToastStateStore
    private let snoozeService: SnoozeServiceProtocol
    private let dismiss: () -> Void

    init(
        state: SnoozeState,
        upsellScreenPresenter: UpsellScreenPresenter,
        toastStateStore: ToastStateStore,
        snoozeService: SnoozeServiceProtocol = SnoozeService(mailUserSession: { AppContext.shared.userSession }),
        dismiss: @escaping () -> Void
    ) {
        self.state = state
        self.upsellScreenPresenter = upsellScreenPresenter
        self.toastStateStore = toastStateStore
        self.snoozeService = snoozeService
        self.dismiss = dismiss
    }

    func handle(action: SnoozeViewAction) async {
        switch action {
        case .customButtonTapped:
            transition(to: .custom)
        case .upgradeTapped:
            do {
                let upsellScreenModel = try await upsellScreenPresenter.presentUpsellScreen(entryPoint: .snooze)
                state = state.copy(\.presentUpsellScreen, to: upsellScreenModel)
            } catch {
                toastStateStore.present(toast: .error(message: error.localizedDescription))
            }
        case .predefinedSnoozeOptionTapped(let snoozeTime):
            if let timestamp = snoozeTime.timestamp {
                snoozeConversations(snoozeTime: timestamp)
            }
        case .unsnoozeTapped:
            unsnoozeConversations()
        case .customSnoozeCancelTapped:
            transition(to: .main)
        case .loadData:
            loadSnoozeData()
        }
    }

    private func transition(to screen: SnoozeView.Screen) {
        withAnimation {
            state =
                state
                .copy(\.screen, to: screen)
                .copy(\.allowedDetents, to: screen.allowedDetents)
                .copy(\.currentDetent, to: screen.detent)
        } completion: { [weak self] in
            guard let self else { return }
            self.state = self.state
                .copy(\.allowedDetents, to: [screen.detent])
        }
    }

    private func loadSnoozeData() {
        do {
            let snoozeActions = try snoozeService.availableSnoozeActionsForConversation(
                weekStart: DateEnvironment.calendar.nonDefaultWeekStart,
                id: state.conversationIDs.first!  // FIXME: - Change this
            ).get()

            state =
                state
                .copy(\.options, to: snoozeActions.options)
                .copy(\.showUnsnooze, to: snoozeActions.showUnsnooze)
        } catch {
            // FIXME: - Add logger
        }
    }

    private func snoozeConversations(snoozeTime: UnixTimestamp) {
        do {
            try snoozeService.snoozeConversations(ids: state.conversationIDs, snoozeTime: snoozeTime).get()
            // FIXME: - Present toast
            dismiss()
        } catch {
            // FIXME: - Add logger
        }
    }

    private func unsnoozeConversations() {
        do {
            try snoozeService.unsnoozeConversations(ids: state.conversationIDs).get()
            // FIXME: - Present toast
            dismiss()
        } catch {
            // FIXME: - Add logger
        }
    }

}

extension SnoozeView.Screen {

    var detent: PresentationDetent {
        switch self {
        case .custom:
            .large
        case .main:
            .medium
        }
    }

    var allowedDetents: Set<PresentationDetent> {
        Set(Self.allCases.map(\.detent))
    }

}

enum OSWeekStart: Int {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

private extension Calendar {

    var nonDefaultWeekStart: NonDefaultWeekStart {
        switch OSWeekStart(rawValue: firstWeekday)! {
        case .monday: .monday
        case .saturday: .saturday
        case .sunday: .sunday
        case .tuesday, .wednesday, .thursday, .friday:
            .sunday
        }

    }

}

extension AvailableSnoozeActionsForConversationResult {
    func get() throws(SnoozeError) -> SnoozeActions {
        switch self {
        case .ok(let value):
            return value
        case .error(let error):
            throw error
        }
    }
}

extension UnsnoozeConversationsResult {

    func get() throws(SnoozeError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }

}

extension SnoozeConversationsResult {

    func get() throws(SnoozeError) {
        switch self {
        case .ok:
            break
        case .error(let error):
            throw error
        }
    }

}

extension SnoozeTime {

    var timestamp: UnixTimestamp? {
        switch self {
        case .tomorrow(let timestamp), .laterThisWeek(let timestamp), .thisWeekend(let timestamp), .nextWeek(let timestamp):
            timestamp
        case .custom:
            nil
        }
    }

}
