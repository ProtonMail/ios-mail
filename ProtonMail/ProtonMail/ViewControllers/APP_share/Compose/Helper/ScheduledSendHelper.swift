// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
import ProtonCore_UIFoundations
import UIKit

// sourcery: mock
protocol ScheduledSendHelperDelegate: AnyObject {
    func actionSheetWillAppear()
    func actionSheetWillDisappear()
    func scheduledTimeIsSet(date: Date?)
    func showSendInTheFutureAlert()
    func isItAPaidUser() -> Bool
    func showScheduleSendPromotionView()
}

extension ScheduledSendHelperDelegate {
    func actionSheetWillAppear() { }
    func actionSheetWillDisappear() { }
}

final class ScheduledSendHelper {
    private var current = Date()
    private weak var viewController: UIViewController?
    private var actionSheet: PMActionSheet?
    private weak var delegate: ScheduledSendHelperDelegate?
    private let originalScheduledTime: OriginalScheduleDate?

    var isActionSheetShownOnView: Bool {
        guard let viewController = self.viewController else {
            return false
        }
        return (viewController.navigationController ?? viewController)
            .view.subviews
            .contains(where: { $0 is PMActionSheet })
    }

    init(
        viewController: UIViewController,
        delegate: ScheduledSendHelperDelegate,
        originalScheduledTime: OriginalScheduleDate?
    ) {
        self.viewController = viewController
        self.delegate = delegate
        self.originalScheduledTime = originalScheduledTime
    }

    func presentActionSheet(date: Date = Date()) {
        guard let viewController = viewController else { return }
        guard !isActionSheetShownOnView else {
            return
        }

        let vcs = viewController.children + [viewController]
        vcs.forEach { controller in
            controller.view.becomeFirstResponder()
            controller.view.endEditing(true)
        }
        self.current = date

        let header = self.setUpActionHeader()

        let actions = [
            setUpAsScheduledAction(),
            setUpTomorrowAction(),
            setUpMondayAction(),
            setUpCustomAction()
        ].compactMap { $0 }
        let items = PMActionSheetItemGroup(items: actions, style: .clickable)

        self.actionSheet = PMActionSheet(headerView: header, itemGroups: [items], enableBGTap: true)
        self.actionSheet?.eventsListener = self
        self.actionSheet?.presentAt(viewController.navigationController ?? viewController,
                                    animated: true)
    }
}

// MARK: Scheduled send action sheet related
extension ScheduledSendHelper {
    private func setUpActionHeader() -> PMActionSheetHeaderView {
        let title = LocalString._general_schedule_send_action
        let header = PMActionSheetHeaderView(
            title: title,
            subtitle: "",
            leftItem: .right(IconProvider.cross),
            rightItem: nil,
            showDragBar: false,
            leftItemHandler: { [weak self] in
                self?.actionSheet?.dismiss(animated: true)
            }
        )
        return header
    }

    private func setUpTomorrowAction() -> PMActionSheetItem? {
        let date: Date?
        let title: String
        if (0..<6).contains(current.hour) {
            date = current.today(at: 8, minute: 0)
            title = L11n.ScheduledSend.inTheMorning
        } else {
            date = current.tomorrow(at: 8, minute: 0)
            title = L11n.ScheduledSend.tomorrow
        }

        guard let date = date else {
            return nil
        }

        return PMActionSheetItem(components: [
            PMActionSheetTextComponent(text: .left(title), edge: [nil, nil, nil, 16]),
            PMActionSheetTextComponent(text: .left(date.localizedString(withTemplate: nil)),
                                       edge: [nil, nil, nil, 16],
                                       compressionResistancePriority: .required)
        ]) { [weak self] _ in
            self?.delegate?.scheduledTimeIsSet(date: date)
            self?.actionSheet?.dismiss(animated: true)
        }
    }

    private func setUpMondayAction() -> PMActionSheetItem? {
        guard let next = self.current.next(.monday, hour: 8, minute: 0) else {
            return nil
        }
        return PMActionSheetItem(components: [
            PMActionSheetTextComponent(text: .left(next.formattedWith("EEEE").capitalized), edge: [nil, nil, nil, 16]),
            PMActionSheetTextComponent(text: .left(next.localizedString(withTemplate: nil)),
                                       edge: [nil, nil, nil, 16],
                                       compressionResistancePriority: .required)
        ]) { [weak self] _ in
            self?.delegate?.scheduledTimeIsSet(date: next)
            self?.actionSheet?.dismiss(animated: true)
        }
    }

    private func setUpCustomAction() -> PMActionSheetItem {
        let isPaid = delegate?.isItAPaidUser() ?? false
        return PMActionSheetItem(components: isPaid ? [
            PMActionSheetTextComponent(text: .left(L11n.ScheduledSend.custom), edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: IconProvider.chevronRight, edge: [nil, nil, nil, 16])
        ] : [
            PMActionSheetTextComponent(text: .left(L11n.ScheduledSend.custom), edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: Asset.upgradeIcon.image,
                                       size: Asset.upgradeIcon.image.size,
                                       edge: [nil, nil, nil, 16]),
            PMActionSheetIconComponent(icon: IconProvider.chevronRight, edge: [nil, nil, nil, 16])
        ]) { [weak self] _ in
            guard let self = self,
                  let viewController = self.viewController,
                  let parentView = viewController.navigationController?.view ?? viewController.view else { return }
            if self.delegate?.isItAPaidUser() == true {
                let picker = PMDatePicker(delegate: self,
                                          cancelTitle: LocalString._general_cancel_action,
                                          saveTitle: LocalString._general_schedule_send_action)
                picker.present(on: parentView)
            } else {
                self.delegate?.showScheduleSendPromotionView()
            }
            self.actionSheet?.dismiss(animated: true)
        }
    }

    private func setUpAsScheduledAction() -> PMActionSheetItem? {
        guard let originalTime = originalScheduledTime?.rawValue else {
            return nil
        }
        return PMActionSheetItem(components: [
            PMActionSheetTextComponent(text: .left(L11n.ScheduledSend.asSchedule), edge: [nil, nil, nil, 16]),
            PMActionSheetTextComponent(text: .left(originalTime.localizedString(withTemplate: nil)),
                                       edge: [nil, nil, nil, 16],
                                       compressionResistancePriority: .required)
        ]) { [weak self] _ in
            guard Date(timeInterval: Constants.ScheduleSend.minNumberOfSeconds, since: Date()) < originalTime else {
                self?.showSendInTheFutureAlert()
                return
            }

            self?.delegate?.scheduledTimeIsSet(date: originalTime)
            self?.actionSheet?.dismiss(animated: true)
        }
    }
}

extension ScheduledSendHelper: PMDatePickerDelegate {
    func showSendInTheFutureAlert() {
        delegate?.showSendInTheFutureAlert()
    }

    func save(date: Date) {
        self.delegate?.scheduledTimeIsSet(date: date)
    }

    func cancel() {
        self.presentActionSheet()
    }
}

extension ScheduledSendHelper: PMActionSheetEventsListener {
    func didDismiss() { }

    func willPresent() {
        self.delegate?.actionSheetWillAppear()
    }

    func willDismiss() {
        self.delegate?.actionSheetWillDisappear()
    }
}
