//
//  ComposeCoordinator.swift
//  ProtonMail - Created on 10/29/18.
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
class ComposeCoordinator : DefaultCoordinator {
    typealias VC = ComposeViewController

    weak var viewController: ComposeViewController?
    let viewModel : ComposeViewModel
    
    init(vc: ComposeViewController, vm: ComposeViewModel) {
        self.viewModel = vm
        self.viewController = vc
    }
    
    internal var navigationController: UINavigationController?
    init(navigation: UINavigationController, vm: ComposeViewModel) {
        self.viewModel = vm
        self.navigationController = navigation
        let rootViewController = UIStoryboard.instantiateInitialViewController(storyboard: .composer)!
        let composer = rootViewController.children[0] as! ComposeViewController
        self.viewController = composer
    }
    
    weak var delegate: CoordinatorDelegate?

    enum Destination : String {
        case password = "to_eo_password_segue"
        case expirationWarning = "expiration_warning_segue"
        case subSelection = "toContactGroupSubSelection"
    }
    
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        
        switch dest {
        case .password:
            guard let popup = destination as? ComposePasswordViewController else {
                return false
            }
            //popup.pwdDelegate = self
            //get this data from view model
            popup.setupPasswords("self.encryptionPassword", confirmPassword: "self.encryptionConfirmPassword", hint: "self.encryptionPasswordHint")

        case .expirationWarning:
            //let popup = segue.destination as! ExpirationWarningViewController
            //popup.delegate = self
            //let nonePMEmail = self.encryptionPassword.count <= 0 ? self.headerView.nonePMEmails : [String]()
            //popup.config(needPwd: nonePMEmail, pgp: self.headerView.pgpEmails)
            return false
        case .subSelection:
            return true
        }
        return true
    }
    
    func start() {
        if let navigation = self.navigationController, let vc = self.viewController {
            navigation.setViewControllers([vc], animated: true)
        }
    }
    
    func go(to dest: Destination) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: nil)
    }
}

//
//override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//    if segue.identifier == kPasswordSegue {
//        let popup = segue.destination as! ComposePasswordViewController
//        popup.pwdDelegate = self
//        popup.setupPasswords(self.encryptionPassword, confirmPassword: self.encryptionConfirmPassword, hint: self.encryptionPasswordHint)
//        self.setPresentationStyleForSelfController(self, presentingController: popup)
//    } else if segue.identifier == kExpirationWarningSegue {
//        let popup = segue.destination as! ExpirationWarningViewController
//        popup.delegate = self
//        let nonePMEmail = self.encryptionPassword.count <= 0 ? self.composeView.nonePMEmails : [String]()
//        popup.config(needPwd: nonePMEmail,
//                     pgp: self.composeView.pgpEmails)
//    } else if segue.identifier == kToContactGroupSubSelection {
//        let destination = segue.destination as! ContactGroupSubSelectionViewController
//        let sender = sender as! (ContactGroupVO, (([DraftEmailData]) -> Void))
//        
//        destination.contactGroupName = sender.0.contactTitle
//        destination.selectedEmails = sender.0.getSelectedEmailData()
//        destination.callback = sender.1
//        self.setPresentationStyleForSelfController(self, presentingController: destination)
//    }
//}
