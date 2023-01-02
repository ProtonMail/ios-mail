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

protocol PMDatePickerDelegate: AnyObject {
    func save(date: Date)
    func cancel()
    func datePickerWillAppear()
    func datePickerWillDisappear()
    func datePickerDidDisappear()
    func showSendInTheFutureAlert()
}

extension PMDatePickerDelegate {
    func datePickerWillAppear() {}
    func datePickerWillDisappear() {}
    func datePickerDidDisappear() {}
}

final class PMDatePicker: UIView {
    private var backgroundView: UIView
    private var container: UIView!
    private var containerBottom: NSLayoutConstraint!
    private var datePicker: UIDatePicker
    private let pickerHeight: CGFloat
    private let cancelTitle: String
    private let saveTitle: String
    private weak var delegate: PMDatePickerDelegate?

    init(delegate: PMDatePickerDelegate,
         cancelTitle: String,
         saveTitle: String) {
        self.delegate = delegate
        self.backgroundView = UIView(frame: .zero)
        self.datePicker = UIDatePicker(frame: .zero)
        self.cancelTitle = cancelTitle
        self.saveTitle = saveTitle
        if #available(iOS 14, *) {
            self.pickerHeight = 450
        } else if #available(iOS 13.4, *) {
            self.pickerHeight = 250
        } else {
            self.pickerHeight = 250
        }
        super.init(frame: .zero)
        self.setUpView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(on parentView: UIView) {
        parentView.addSubview(self)
        self.fillSuperview()
        parentView.layoutIfNeeded()

        self.delegate?.datePickerWillAppear()
        self.containerBottom.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
        if #available(iOS 15, *) {
        } else if #available(iOS 14, *) {
            NotificationCenter.default.addKeyboardObserver(self)
        }
    }
}

// MARK: Actions
extension PMDatePicker {
    @objc
    private func clickSaveButton() {
        guard Date(timeInterval: Constants.ScheduleSend.minNumberOfSeconds, since: Date()) < self.datePicker.date else {
            delegate?.showSendInTheFutureAlert()
            return
        }
        self.delegate?.save(date: self.datePicker.date)
        self.dismiss(isCancelled: false)
    }

    @objc
    private func clickCancelButton() {
        self.dismiss(isCancelled: true)
    }

    private func dismiss(isCancelled: Bool) {
        if isCancelled {
            self.delegate?.cancel()
        }
        self.delegate?.datePickerWillDisappear()
        self.containerBottom.constant = self.pickerHeight
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.layoutIfNeeded()
            }, completion: { _ in
                self.removeFromSuperview()
                self.delegate?.datePickerDidDisappear()
            }
        )
    }
}

// MARK: View set up
extension PMDatePicker {
    private func setUpView() {
        self.setUpBackgroundView()
        let container = self.setUpContainer()
        let toolBar = self.setUpToolBar(in: container)
        self.setUpDatePicker(in: container, toolBar: toolBar)
    }

    private func setUpBackgroundView() {
        self.backgroundView.backgroundColor = ColorProvider.BlenderNorm
        self.addSubview(self.backgroundView)
        self.backgroundView.fillSuperview()
    }

    private func setUpContainer() -> UIView {
        let container = UIView(frame: .zero)
        container.backgroundColor = ColorProvider.BackgroundNorm
        self.addSubview(container)

        [
            container.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: self.trailingAnchor)
        ].activate()
        self.containerBottom = container.bottomAnchor.constraint(
            equalTo: self.bottomAnchor,
            constant: self.pickerHeight
        )
        self.containerBottom.isActive = true
        self.container = container
        return container
    }

    private func setUpToolBar(in container: UIView) -> UIToolbar {
        let screenWidth = UIScreen.main.bounds.width
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: screenWidth, height: 44))

        let saveItem = UIBarButtonItem(title: self.saveTitle,
                                       style: .plain,
                                       target: self,
                                       action: #selector(self.clickSaveButton))
        saveItem.tintColor = ColorProvider.InteractionNorm
        let cancelItem = UIBarButtonItem(title: self.cancelTitle,
                                         style: .plain,
                                         target: self,
                                         action: #selector(self.clickCancelButton))
        cancelItem.tintColor = ColorProvider.InteractionNorm
        let flexItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        toolBar.setItems([cancelItem, flexItem, saveItem], animated: false)

        container.addSubview(toolBar)
        [
            toolBar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            toolBar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            toolBar.topAnchor.constraint(equalTo: container.topAnchor)
        ].activate()
        return toolBar
    }

    private func setUpDatePicker(in container: UIView, toolBar: UIToolbar) {
        self.delegate?.datePickerWillAppear()
        self.datePicker.datePickerMode = .dateAndTime
        self.datePicker.minuteInterval = Constants.ScheduleSend.minNumberOfMinutes
        let baseDate = PMDatePicker.referenceDate()
        let minimumDate = Date(timeInterval: Constants.ScheduleSend.minNumberOfSeconds, since: baseDate)
        self.datePicker.date = minimumDate
        self.datePicker.minimumDate = minimumDate
        self.datePicker.maximumDate = Date(timeInterval: Constants.ScheduleSend.maxNumberOfSeconds, since: Date())
        self.datePicker.tintColor = ColorProvider.BrandNorm
        datePicker.addTarget(self, action: #selector(self.pickerDateIsChanged), for: .valueChanged)

        let height = self.pickerHeight
        if #available(iOS 14, *) {
            self.datePicker.preferredDatePickerStyle = .inline
        } else if #available(iOS 13.4, *) {
            self.datePicker.preferredDatePickerStyle = .wheels
        }

        container.addSubview(self.datePicker)
        [
            self.datePicker.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            self.datePicker.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            self.datePicker.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            self.datePicker.topAnchor.constraint(equalTo: toolBar.bottomAnchor),
            self.datePicker.heightAnchor.constraint(equalToConstant: height)
        ].activate()
    }

    static func referenceDate(from date: Date = Date()) -> Date {
        let seconds = (date.timeIntervalSince1970 / 300.0).rounded(.up) * 300.0
        let date = Date(timeIntervalSince1970: seconds)
        return date
    }

    @objc
    func pickerDateIsChanged() {
        // Let's say you only change day and not touch hour time
        // if the new date is over maximumDate
        // datePicker.date will update by itself to fit maximumDate, that is great
        // but the UI won't update...
        // this function is to update the confused UI
        var date = datePicker.date
        if date == datePicker.maximumDate && date.minute % 5 == 0 {
            // If the minute is multiple of 5, needs to minus 1 to show correct UI
            date = date.add(.minute, value: -1) ?? date
        }
        datePicker.setDate(date, animated: false)
    }
}

extension PMDatePicker: NSNotificationCenterKeyboardObserverProtocol {
    @objc
    func keyboardWillHideNotification(_ notification: Notification) {
        containerBottom.constant = 0
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }

    @objc
    func keyboardWillShowNotification(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardInfo = userInfo["UIKeyboardBoundsUserInfoKey"] as? CGRect else {
            return
        }
        containerBottom.constant = -(keyboardInfo.height - 57)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
}
