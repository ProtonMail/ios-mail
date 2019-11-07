//
//  File.swift
//  ProtonMail - Created on 07/03/2019.
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
    

import Foundation
import SafariServices

class MessageBodyCoordinator {
    private weak var controller: MessageBodyViewController!
    private let kToComposerSegue : String    = "toCompose"
    
    init(controller: MessageBodyViewController,
         enclosingScroller: ScrollableContainer)
    {
        self.controller = controller
        self.controller.enclosingScroller = enclosingScroller
    }
    
    internal func open(url originalURL: URL) {
        if userCachedStatus.browser == .inAppBrowser {
            let safari = SFSafariViewController(url: originalURL)
            controller.present(safari, animated: true)
        } else {
            var urlToOpen = originalURL

            if let customSchemeURL = userCachedStatus.browser.deeplink(to: originalURL),
                UIApplication.shared.canOpenURL(customSchemeURL)
            {
                urlToOpen = customSchemeURL
            }

            UIApplication.shared.open(urlToOpen, options: [:], completionHandler: nil)
        }
    }
    
    internal func mail(to url: URL) {
        self.controller.performSegue(withIdentifier: kToComposerSegue, sender: url)
    }
    
    internal func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == kToComposerSegue {
            let viewModel = ContainableComposeViewModel(msg: nil, action: .newDraft)
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
            guard let navigator = segue.destination as? UINavigationController,
            let next = navigator.viewControllers.first as? ComposeContainerViewController else
            {
                assert(false, "Wrong root view controller in Compose storyboard")
                return
            }
            next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
            next.set(coordinator: ComposeContainerViewCoordinator(controller: next))
        }
    }
}

extension MessageBodyCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
