//
//  NSNotification+KeyboardExtension.swift
//  ProtonMail
//
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

import UIKit

public struct KeyboardInfo {
    public let beginFrame: CGRect
    public let endFrame: CGRect
    public let duration: TimeInterval
    public let animationOption: UIView.AnimationOptions = .beginFromCurrentState

    init(beginFrame: CGRect, endFrame: CGRect, duration: TimeInterval) {
        self.beginFrame = beginFrame
        self.endFrame = endFrame
        self.duration = duration
    }
}

extension Notification {
    public var keyboardInfo: KeyboardInfo {
        let beginFrame = (userInfo?[UIResponder.keyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let endFrame = (userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? CGRect.zero
        let duration = (userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0

        return KeyboardInfo(beginFrame: beginFrame, endFrame: endFrame, duration: duration)
    }
}
