//
//  UIScrollView+Extensions.swift
//  PMLogin - Created on 01.12.2020.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import UIKit

extension UIScrollView {
    func adjustForKeyboard(notification: NSNotification) {
        switch notification.name {
        case UIResponder.keyboardWillShowNotification:
            guard let keyboardFrame = notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
                contentInset.bottom = 0
                return
            }
            contentInset.bottom = superview?.convert(keyboardFrame.cgRectValue, from: nil).size.height ?? 0
        case UIResponder.keyboardWillHideNotification:
            contentInset.bottom = 0
        default:
            fatalError("Invalid usage")
        }
    }
}
