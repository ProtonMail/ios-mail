//
//  Deeplinkable.swift
//  ProtonMail - Created on 23/07/2019.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
    

import UIKit

protocol Deeplinkable: class {
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
    
    func cutDeeplink(downTo path: DeepLink.Node) {
        guard let deeplink = self.deeplinkStorage else {
            assert(false, "Controller does not have UIWindowScene available")
            return
        }
        deeplink.cut(until: path)
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
