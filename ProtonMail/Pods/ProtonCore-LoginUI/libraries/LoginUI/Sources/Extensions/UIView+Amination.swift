//
//  UIView+Amination.swift
//  ProtonCore-Login - Created on 26.03.21.
//
//  Copyright (c) 2022 Proton Technologies AG
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

import UIKit

extension UIView {
    func fadeIn(withDuration duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        fade(withDuration: duration, alpha: 1.0, completion: completion)
    }

    func fadeOut(withDuration duration: TimeInterval = 1.0, completion: (() -> Void)? = nil) {
        fade(withDuration: duration, alpha: 0.0, completion: completion)
    }

    private func fade(withDuration duration: TimeInterval, alpha: CGFloat, completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: duration, animations: {
            self.alpha = alpha
        }, completion: { _ in
            completion?()
        })
    }
}
