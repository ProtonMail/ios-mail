//
//  File.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageBodyCoordinator {
    private weak var controller: MessageBodyViewController!
    private let kToComposerSegue : String    = "toCompose"
    
    init(controller: MessageBodyViewController,
         enclosingScroller: MessageBodyScrollingDelegate)
    {
        self.controller = controller
        self.controller.enclosingScroller = enclosingScroller
    }
    
    internal func open(url: URL) {
        UIApplication.shared.openURL(url)
    }
    
    internal func mail(to url: URL) {
        self.controller.performSegue(withIdentifier: kToComposerSegue, sender: url)
    }
    
    internal func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToComposerSegue {
            let viewModel = EditorViewModel(msg: nil, action: .newDraft)
            if let mailTo : NSURL = sender as? NSURL, mailTo.scheme == "mailto", let resSpecifier = mailTo.resourceSpecifier {
                var rawURLparts = resSpecifier.components(separatedBy: "?")
                if (rawURLparts.count > 2) {
                    
                } else {
                    let defaultRecipient = rawURLparts[0]
                    if defaultRecipient.count > 0 { //default to
                        if defaultRecipient.isValidEmail() {
                            viewModel.addToContacts(ContactVO(name: defaultRecipient, email: defaultRecipient))
                        }
                        PMLog.D("to: \(defaultRecipient)")
                    }
                    
                    if (rawURLparts.count == 2) {
                        let queryString = rawURLparts[1]
                        let params = queryString.components(separatedBy: "&")
                        for param in params {
                            var keyValue = param.components(separatedBy: "=")
                            if (keyValue.count != 2) {
                                continue
                            }
                            let key = keyValue[0].lowercased()
                            var value = keyValue[1]
                            value = value.removingPercentEncoding ?? ""
                            if key == "subject" {
                                PMLog.D("subject: \(value)")
                                viewModel.setSubject(value)
                            }
                            
                            if key == "body" {
                                PMLog.D("body: \(value)")
                                viewModel.setBody(value)
                            }
                            
                            if key == "to" {
                                PMLog.D("to: \(value)")
                                if value.isValidEmail() {
                                    viewModel.addToContacts(ContactVO(name: value, email: value))
                                }
                            }
                            
                            if key == "cc" {
                                PMLog.D("cc: \(value)")
                                if value.isValidEmail() {
                                    viewModel.addCcContacts(ContactVO(name: value, email: value))
                                }
                            }
                            
                            if key == "bcc" {
                                PMLog.D("bcc: \(value)")
                                if value.isValidEmail() {
                                    viewModel.addBccContacts(ContactVO(name: value, email: value))
                                }
                            }
                        }
                    }
                }
            }
            let next = UIStoryboard(name: "Composer", bundle: nil).make(ComposeContainerViewController.self)
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
            let navigator = UINavigationController.init(rootViewController: next)
            self.controller.present(navigator, animated: true, completion: nil)
        }
    }
}

extension MessageBodyCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
