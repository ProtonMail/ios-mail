//
//  UIScrollView+Extensions.swift
//  ProtonCore-Login - Created on 01.12.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

extension NotificationCenter {

    func setupKeyboardNotifications(target: Any, show: Selector, hide: Selector) {
        addObserver(target, selector: show, name: UIResponder.keyboardWillShowNotification, object: nil)
        addObserver(target, selector: hide, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
}

extension UIViewController {

    func adjust(_ scrollView: UIScrollView, notification: NSNotification, topView: UIView, bottomView: UIView) {
        guard navigationController?.topViewController === self else { return }
        scrollView.adjust(forKeyboardVisibilityNotification: notification)
        scrollView.ensureVisibility(of: topView, downToIfPossible: bottomView)
    }

    func topView(of first: UIView, _ second: UIView, _ views: UIView...) -> UIView {
        ([first] + [second] + views).first { $0.isFirstResponder } ?? first
    }
}

extension UIScrollView {

    func adjust(forKeyboardVisibilityNotification notification: NSNotification?) {

        guard let notification = notification else {
            centerIfNeeded()
            return
        }

        switch notification.name {

        case UIResponder.keyboardWillShowNotification, UIResponder.keyboardDidShowNotification:
            guard let userInfo = notification.userInfo,
                  let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                contentInset.bottom = 0
                centerIfNeeded()
                return
            }
            let keyboardHeight = superview?.convert(keyboardFrame.cgRectValue, from: nil).size.height ?? 0
            let offsetToMove = keyboardHeight - contentInset.top
            if offsetToMove > 0 {
                if offsetToMove < bounds.size.height - keyboardHeight {
                    contentInset.bottom = offsetToMove
                } else {
                    contentInset.bottom = keyboardHeight
                }
            }
            centerIfNeeded()

        case UIResponder.keyboardWillHideNotification, UIResponder.keyboardDidHideNotification:
            contentInset.bottom = 0
            centerIfNeeded()

        default:
            assertionFailure("\(#function) should never be called with non-keyboard notification")
        }
    }

    private func centerIfNeeded() {
        guard traitCollection.horizontalSizeClass == .regular else { return }
        let offset = (bounds.height - contentInset.bottom - contentSize.height) / 2.0
        let limitedOffset = max(0, offset)
        contentInset.top = limitedOffset
    }

    fileprivate func ensureVisibility(of topView: UIView, downToIfPossible bottomView: UIView) {
        let topRect = convert(topView.frame, from: topView.superview)
        let bottomRect = convert(bottomView.frame, from: bottomView.superview)
        var visibleRect = topRect.union(bottomRect)
        let availableHeight = bounds.height - contentInset.bottom
        visibleRect.origin.y -= 24
        visibleRect.size.height = min(availableHeight, visibleRect.height + 24)
        scrollRectToVisible(visibleRect, animated: false)
    }
}
