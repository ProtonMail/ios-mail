// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreServices
import ProtonCoreUIFoundations
import UIKit

protocol SnoozeSupport: AnyObject {
    var conversationDataService: ConversationDataServiceProxy { get }
    var calendar: Calendar { get }
    var isPaidUser: Bool { get }
    var presentingView: UIView { get }
    var snoozeConversations: [ConversationID] { get }
    var snoozeDateConfigReceiver: SnoozeDateConfigReceiver { get }
    var weekStart: WeekStart { get }

    func presentDatePickerForSnooze()
    func presentSnoozeConfigSheet(on viewController: UIViewController, current: Date)

    @MainActor
    func showSnoozeSuccessBanner(on date: Date)
    func presentPaymentView()
    func willSnooze()
}

extension SnoozeSupport {
    func presentDatePickerForSnooze() {
        if isPaidUser {
            let picker = PMDatePicker(
                delegate: snoozeDateConfigReceiver,
                cancelTitle: LocalString._general_cancel_action,
                saveTitle: L10n.Snooze.title,
                pickerType: .snooze
            )
            picker.present(on: presentingView)
        } else {
            presentPaymentView()
        }
    }

    func presentSnoozeConfigSheet(on viewController: UIViewController, current: Date) {
        let presentingVC = viewController.navigationController ?? viewController
        let header = setUpActionHeader(dismiss: { [weak presentingVC] in
            guard
                let presentingVC = presentingVC,
                let sheet = presentingVC.view.subviews.first(where: { $0 is PMActionSheet }) as? PMActionSheet
            else { return }
            sheet.dismiss(animated: true)
        })

        let actions = [
            setUpTomorrowAction(current: current),
            setUpLaterThisWeek(current: current),
            setUpThisWeekend(current: current),
            setUpNextWeek(current: current),
            setUpCustom()
        ].compactMap { $0 }
        let items = PMActionSheetItemGroup(items: actions, style: .clickable)

        let actionSheet = PMActionSheet(headerView: header, itemGroups: [items], enableBGTap: true)
        actionSheet.presentAt(presentingVC, hasTopConstant: false, animated: true)
    }

    func snooze(on date: Date, completion: (() -> Void)? = nil) {
        conversationDataService.snooze(conversationIDs: snoozeConversations, on: date) {
            completion?()
        }
        Task {
            await showSnoozeSuccessBanner(on: date)
        }
    }

    func willSnooze() {
        // Override this when you want to do anything before snoozing
    }
}

// MARK: - Action sheet setting
extension SnoozeSupport {
    private func setUpActionHeader(dismiss: @escaping () -> Void) -> PMActionSheetHeaderView {
        let header = PMActionSheetHeaderView(
            title: L10n.Snooze.snoozeUntil,
            subtitle: "",
            leftItem: .right(IconProvider.cross),
            rightItem: nil,
            showDragBar: false,
            leftItemHandler: { dismiss() }
        )
        return header
    }

    func setUpTomorrowAction(current: Date) -> PMActionSheetItem? {
        guard let date = current.tomorrow(at: Constants.Snooze.snoozeHour, minute: 0) else { return nil }
        return actionItem(optionTitle: L10n.ScheduledSend.tomorrow, date: date)
    }

    func setUpLaterThisWeek(current: Date) -> PMActionSheetItem? {
        let validWeekDays: [Date.Weekday] = [.monday, .tuesday, .wednesday, .friday]
        let validWeekDaysRaw = validWeekDays.map(\.rawValue)

        guard
            validWeekDaysRaw.contains(current.weekday),
            let date = current
                .tomorrow(at: Constants.Snooze.snoozeHour, minute: 0)?
                .tomorrow(at: Constants.Snooze.snoozeHour, minute: 0)
        else { return nil }
        return actionItem(optionTitle: L10n.Snooze.laterThisWeek, date: date)
    }

    func setUpThisWeekend(current: Date) -> PMActionSheetItem? {
        let validWeekDays: [Date.Weekday] = [.monday, .tuesday, .wednesday, .thursday]
        let validWeekDaysRaw = validWeekDays.map(\.rawValue)

        let isMonday = weekStart == .monday || (weekStart == .automatic && isDefaultWeekStart(equalTo: .monday))
        guard
            isMonday,
            validWeekDaysRaw.contains(current.weekday),
            let date = current.next(.saturday, hour: Constants.Snooze.snoozeHour, minute: 0)
        else { return nil }
        return actionItem(optionTitle: L10n.Snooze.thisWeekend, date: date)
    }

    func setUpNextWeek(current: Date) -> PMActionSheetItem? {
        if current.weekday == 1 { return nil }

        var weekStart = self.weekStart
        if weekStart == .automatic {
            if isDefaultWeekStart(equalTo: .monday) {
                weekStart = .monday
            } else if isDefaultWeekStart(equalTo: .saturday) {
                weekStart = .saturday
            } else if isDefaultWeekStart(equalTo: .sunday) {
                weekStart = .sunday
            }
        }
        var date: Date?
        switch weekStart {
        case .monday:
            date = current.next(.monday, hour: Constants.Snooze.snoozeHour, minute: 0)
        case .saturday:
            date = current.next(.saturday, hour: Constants.Snooze.snoozeHour, minute: 0)
        case .sunday:
            date = current.next(.sunday, hour: Constants.Snooze.snoozeHour, minute: 0)
        case .automatic:
            date = nil
            PMAssertionFailure("Unexpected week start: \(calendar.firstWeekday)")
        }
        guard let date = date else { return nil }
        return actionItem(optionTitle: L10n.Snooze.nextWeek, date: date)
    }

    private func setUpCustom() -> PMActionSheetItem? {
        let paidUserComponents: [any PMActionSheetComponent] = [
            PMActionSheetTextComponent(text: .left(L10n.ScheduledSend.custom), edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: IconProvider.chevronRight, edge: [nil, nil, nil, 16])
        ]

        let freeUserComponents: [any PMActionSheetComponent] = [
            PMActionSheetTextComponent(text: .left(L10n.ScheduledSend.custom), edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: Asset.upgradeIcon.image,
                                       size: Asset.upgradeIcon.image.size,
                                       edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: IconProvider.chevronRight, edge: [nil, nil, nil, 16])
        ]
        let components = isPaidUser ? paidUserComponents : freeUserComponents
        return PMActionSheetItem(components: components) { [weak self] _ in
            self?.presentDatePickerForSnooze()

        }
    }

    private func isDefaultWeekStart(equalTo weekStart: WeekStart) -> Bool {
        switch weekStart {
        case .automatic:
            PMAssertionFailure("Shouldn't compare automatic")
            return calendar.firstWeekday == 1
        case .monday:
            return calendar.firstWeekday == 2
        case .sunday:
            return calendar.firstWeekday == 1
        case .saturday:
            return calendar.firstWeekday == 7
        }
    }

    private func actionItem(optionTitle: String, date: Date) -> PMActionSheetItem {
        PMActionSheetItem(components: [
            PMActionSheetTextComponent(text: .left(optionTitle), edge: [nil, nil, nil, 16]),
            PMActionSheetTextComponent(text: .left(PMDateFormatter.shared.stringForSnoozeOption(from: date)),
                                       edge: [nil, nil, nil, 16],
                                       compressionResistancePriority: .required)
        ]) { [weak self] _ in
            self?.willSnooze()
            self?.snooze(on: date)
        }
    }
}

final class SnoozeDateConfigReceiver: PMDatePickerDelegate {

    var saveDate: (Date) -> Void
    var cancelHandler: () -> Void
    var showSendInTheFutureAlertHandler: () -> Void

    init(
        saveDate: @escaping (Date) -> Void,
        cancelHandler: @escaping () -> Void,
        showSendInTheFutureAlertHandler: @escaping () -> Void
    ) {
        self.saveDate = saveDate
        self.cancelHandler = cancelHandler
        self.showSendInTheFutureAlertHandler = showSendInTheFutureAlertHandler
    }

    func save(date: Date) {
        saveDate(date)
    }

    func cancel() {
        cancelHandler()
    }

    func showSendInTheFutureAlert() {
        showSendInTheFutureAlertHandler()
    }
}
