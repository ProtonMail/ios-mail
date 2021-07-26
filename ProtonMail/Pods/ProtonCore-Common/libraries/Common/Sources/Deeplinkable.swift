//
//  Deeplinkable.swift
//  ProtonCore-Common - Created on 23/07/2019.
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

protocol Deeplinkable: AnyObject {
    var deeplinkNode: DeepLink.Node { get }
    var deeplinkStorage: DeepLink? { get set }
}

extension Coordinated where Self: Deeplinkable {
    func appendDeeplink(path: DeepLink.Node) {
        guard let deeplink = self.deeplinkStorage else {
            assert(false, "Controller does not have UIWindowScene available")
            return
        }
        if deeplink.last != path {
            deeplink.append(path)
        }
        self.deeplinkStorage = deeplink
    }
}

#endif
