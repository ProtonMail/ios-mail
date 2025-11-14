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

@testable import ProtonMail
import InboxSnapshotTesting
import InboxCoreUI
import InboxTesting
import proton_app_uniffi
import ProtonUIFoundations
import Testing

@MainActor
@Suite(.calendarZurichEnUS, .currentDate(.fixture("2025-02-07 09:32:00")))
struct SnoozeViewSnapshotTests {

    struct TestCase {
        let actions: SnoozeActions
        let screen: SnoozeView.Screen
        let name: String
    }

    @Test(
        "all snapshot variants",
        arguments: [
            TestCase(
                actions: .testData(options: [.tomorrow, .laterThisWeek, .thisWeekend, .nextWeek]),
                screen: .main,
                name: "all_4_predefined_options",
            ),
            .init(
                actions: .testData(options: [.tomorrow, .laterThisWeek, .thisWeekend]),
                screen: .main,
                name: "upgrade_button_with_3_options"
            ),
            .init(
                actions: .testData(options: [.tomorrow, .laterThisWeek], showUnsnooze: true),
                screen: .main,
                name: "snooze_button_with_2_options"
            ),
            .init(
                actions: .testData(options: [.tomorrow, .custom], showUnsnooze: true),
                screen: .main,
                name: "snooze_button_with_1_option"
            ),
            .init(
                actions: .testData(options: [.tomorrow, .laterThisWeek, .nextWeek, .custom], showUnsnooze: true),
                screen: .main,
                name: "snooze_button_with_3_options_and_custom_on_grid"
            ),
            .init(actions: .testData(), screen: .custom, name: "custom_view"),
        ]
    )
    func snapshotAllVariants(_ testCase: TestCase) {
        let snoozeView = SnoozeView(
            state: .init(
                conversationIDs: [.init(value: 7)],
                labelId: .init(value: 5),
                screen: testCase.screen,
                snoozeActions: testCase.actions,
                currentDetent: testCase.screen.detent,
                allowedDetents: [testCase.screen.detent]
            ),
            snoozeService: SnoozeServiceSpy()
        )
        .environmentObject(ToastStateStore(initialState: .initial))
        .environmentObject(UpsellCoordinator.dummy)
        .injectDateEnvironments()

        assertSnapshotsOnIPhoneX(of: snoozeView, named: testCase.name)
    }
}

private extension SnoozeActions {

    static func testData(options: [SnoozeTime] = [], showUnsnooze: Bool = false) -> Self {
        .init(options: options, showUnsnooze: showUnsnooze)
    }

}

private extension SnoozeTime {

    private static let timestamp: UInt64 = 1752697012

    static var tomorrow: Self {
        .tomorrow(timestamp)
    }

    static var nextWeek: Self {
        .nextWeek(timestamp)
    }

    static var thisWeekend: Self {
        .thisWeekend(timestamp)
    }

    static var laterThisWeek: Self {
        .laterThisWeek(timestamp)
    }

}

import InboxIAP

extension UpsellCoordinator {

    static var dummy: UpsellCoordinator {
        UpsellCoordinator(
            mailUserSession: .dummy,
            configuration: .mail
        )
    }

}
