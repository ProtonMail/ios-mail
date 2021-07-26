//
//  CoordinatorSegue.swift
//  ProtonCore-Common - Created on 10/29/18.
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

#if canImport(UIKit)
import UIKit

/// when viewController override the 'prepare' function. don't forget to call super. it triggers the setSender.
/// in order to use this. need to set segue class in the storyboard
class CoordinatorSegue: UIStoryboardSegue {
    /// keep the @objc key word. the setSender will not work without it.
    @objc open var sender: AnyObject?

    override func perform() {
        guard let coordinated = self.source as? CoordinatedBase else {
            return
        }

        if let ret = coordinated.getCoordinator()?.navigate(from: self.source,
                                                            to: destination,
                                                            with: identifier,
                                                            and: self.sender), ret == true {
            super.perform()
        }
    }
}
#endif
