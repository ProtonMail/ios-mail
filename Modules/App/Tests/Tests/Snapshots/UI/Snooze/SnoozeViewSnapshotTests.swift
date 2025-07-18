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
import InboxCore
import InboxTesting
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
                actions: .testData(predefined: [.tomorrow, .laterThisWeek, .thisWeekend, .nextWeek]),
                screen: .main,
                name: "all_4_predefined_options",
            ),
            .init(
                actions: .testData(predefined: [.tomorrow, .laterThisWeek, .thisWeekend], customButtonType: .upgrade),
                screen: .main,
                name: "upgrade_button_with_3_options"
            ),
            .init(
                actions: .testData(predefined: [.tomorrow, .laterThisWeek], isUnsnoozeVisible: true, customButtonType: .upgrade),
                screen: .main,
                name: "snooze_button_with_2_options"
            ),
            .init(actions: .testData(), screen: .custom, name: "custom_view"),
        ]
    )
    func snapshotAllVariants(_ testCase: TestCase) {
        let snoozeView = SnoozeView(
            snoozeActions: testCase.actions,
            initialScreen: testCase.screen
        )
        .injectDateEnvironments()

        assertSnapshotsOnIPhoneX(of: snoozeView, named: testCase.name)
    }
}

private extension SnoozeActions {

    static func testData(
        predefined: [PredefinedSnooze] = [],
        isUnsnoozeVisible: Bool = false,
        customButtonType: CustomButtonType = .regular
    ) -> Self {
        .init(predefined: predefined, isUnsnoozeVisible: isUnsnoozeVisible, customButtonType: customButtonType)
    }

}

private extension PredefinedSnooze {

    private static let date = Date(timeIntervalSince1970: 1752697012)

    static var tomorrow: Self {
        .init(type: .tomorrow, date: date)
    }

    static var nextWeek: Self {
        .init(type: .nextWeek, date: date)
    }

    static var thisWeekend: Self {
        .init(type: .thisWeekend, date: date)
    }

    static var laterThisWeek: Self {
        .init(type: .laterThisWeek, date: date)
    }

}
