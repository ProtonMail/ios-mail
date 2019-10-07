//
//  ComposerNavigationController.swift
//  ProtonMail - Created on 14/07/2019.
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

class ComposerNavigationController: UINavigationController {
    
}

@available(iOS, deprecated: 13.0, message: "Multiwindow environment restores state via Deeplinkable conformance")
extension ComposerNavigationController: UIViewControllerRestoration {
    override func applicationFinishedRestoringState() {
        super.applicationFinishedRestoringState()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.restorationIdentifier = String(describing: ComposerNavigationController.self)
        self.restorationClass = ComposerNavigationController.self
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.viewControllers.isEmpty {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    static func viewController(withRestorationIdentifierPath identifierComponents: [String], coder: NSCoder) -> UIViewController? {
        let navigation = ComposerNavigationController()
        navigation.restorationIdentifier = String(describing: ComposerNavigationController.self)
        navigation.restorationClass = ComposerNavigationController.self
        return navigation
    }
}
