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
        snoozeService: SnoozeServiceProtocol,
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
                await snoozeConversations(snoozeTime: timestamp)
            }
        case .unsnoozeTapped:
            await unsnoozeConversations()
        case .customSnoozeCancelTapped:
            transition(to: .main)
        case .customSnoozeDateSelected(let snoozeDate):
            await snoozeConversations(snoozeTime: UnixTimestamp(snoozeDate.timeIntervalSince1970))
        case .loadData:
            await loadSnoozeData()
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

    private func loadSnoozeData() async {
        do {
            let snoozeActions = try await snoozeService.availableSnoozeActions(
                for: state.conversationIDs,
                systemCalendarWeekStart: DateEnvironment.calendar.nonDefaultWeekStart
            ).get()

            state = state.copy(\.snoozeActions, to: snoozeActions)
        } catch {
            showToastIfNeeded(snoozeError: error)
            AppLogger.log(error: error, category: .snooze)
        }
    }

    private func snoozeConversations(snoozeTime: UnixTimestamp) async {
        do {
            _ = try await snoozeService.snooze(
                conversation: state.conversationIDs,
                labelId: state.labelId,
                timestamp: snoozeTime
            ).get()
            toastStateStore.present(toast: .snooze(snoozeDate: snoozeTime.date))
            dismiss()
        } catch {
            showToastIfNeeded(snoozeError: error)
            AppLogger.log(error: error, category: .snooze)
        }
    }

    private func unsnoozeConversations() async {
        do {
            _ = try await snoozeService.unsnooze(
                conversation: state.conversationIDs,
                labelId: state.labelId
            ).get()
            toastStateStore.present(toast: .unsnooze)
            dismiss()
        } catch {
            showToastIfNeeded(snoozeError: error)
            AppLogger.log(error: error, category: .snooze)
        }
    }

    private func showToastIfNeeded(snoozeError: SnoozeError) {
        if case .reason(let snoozeErrorReason) = snoozeError {
            toastStateStore.present(toast: .error(message: snoozeErrorReason.errorMessage.string))
        }
    }

}

extension Toast {
    static var unsnooze: Toast {
        .information(message: L10n.Snooze.conversationUnsnoozed.string)
    }

    static func snooze(snoozeDate: Date) -> Toast {
        .information(
            message:
                L10n.Mailbox.Item.snoozedTill(value: snoozeDate.snoozeFormat()).string
        )
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

private enum OSWeekStart: Int {
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

private extension SnoozeTime {
    var timestamp: UnixTimestamp? {
        switch self {
        case .tomorrow(let timestamp), .laterThisWeek(let timestamp),
            .thisWeekend(let timestamp), .nextWeek(let timestamp):
            timestamp
        case .custom:
            nil
        }
    }
}
