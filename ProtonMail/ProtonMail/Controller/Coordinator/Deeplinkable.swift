//
//  Deeplinkable.swift
//  ProtonMail - Created on 23/07/2019.
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

protocol Deeplinkable: AnyObject {
    var deeplinkNode: DeepLink.Node { get }
    var deeplinkStorage: DeepLink? { get set }
}

extension Deeplinkable where Self: UIViewController {
    var deeplinkStorage: DeepLink? {
        get {
            if #available(iOS 13.0, *) {
                return self.view.window?.windowScene?.deeplink
            } else {
                // FIXME: userDefaults
                return nil
            }
        }
        set {
            if #available(iOS 13.0, *), let deeplink = newValue {
                self.view.window?.windowScene?.deeplink = deeplink
            } else {
                // FIXME: userDefaults
            }
        }
    }
}

extension CoordinatedNew where Self: Deeplinkable {
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

@available(iOS 13.0, *)
extension UIWindowScene {
    var deeplink: DeepLink {
        get {
            var saved = self.session.userInfo?["deeplink"] as? DeepLink
            if saved == nil {
                saved = DeepLink(String(describing: MenuViewController.self))
                self.deeplink = saved!
            }
            return saved!
        }
        set {
            self.session.userInfo?["deeplink"] = newValue
        }
    }
}
