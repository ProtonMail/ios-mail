//
//  UIStoryboard+Extension.swift
//  ProtonMail
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


import Foundation

extension UIStoryboard {
    /// The raw value must match the restorationIdentifier for the initialViewController
    enum Storyboard: String {
        case attachments = "Attachments"
        case inbox = "Menu"
        case signIn = "SignIn"
        case composer = "Composer"
        var restorationIdentifier: String {
            return rawValue
        }
        
        var storyboard: UIStoryboard {
            return UIStoryboard(name: rawValue, bundle: nil)
        }
        
        func instantiateInitialViewController() -> UIViewController? {
            return storyboard.instantiateInitialViewController()
        }
    }
    
    class func instantiateInitialViewController(storyboard: Storyboard) -> UIViewController? {
        return storyboard.instantiateInitialViewController()
    }
}

extension UIStoryboard {
    func make<T>(_ type: T.Type) -> T {
        return self.instantiateViewController(withIdentifier: .init(describing: T.self)) as! T
    }
}
