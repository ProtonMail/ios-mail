//
//  ContactCoordinator.swift
//  ProtonMail - Created on 12/13/18.
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
import SWRevealViewController

class ContactCoordinator : DefaultCoordinator {
    typealias VC = ContactsViewController
    
    let viewModel : ContactsViewModel
    var services: ServiceFactory
    
    internal weak var navigation: UIViewController?
    internal weak var swRevealVC: SWRevealViewController?
    internal weak var viewController: ContactsViewController?
    
    ///
    internal weak var lastestCoordinator: CoordinatorNew?
    
    func start() {
        
    }
    ///
    enum Destination : String {
        case test   = ""
    }
    
    init(rvc: SWRevealViewController?, nav: UIViewController?, vc: ContactsViewController, vm: ContactsViewModel, services: ServiceFactory, deeplink: DeepLink? = nil) {
        self.navigation = nav
        self.swRevealVC = rvc
        self.viewModel = vm
        self.viewController = vc
        self.services = services
    }
    
    func go(to dest: Destination, sender: Any? = nil) {
        self.viewController?.performSegue(withIdentifier: dest.rawValue, sender: sender)
    }
    
    func go(to deepLink: DeepLink) {
        
    }
    
    ///TODO::fixme. add warning or error when return false except the last one.
    func navigate(from source: UIViewController, to destination: UIViewController, with identifier: String?, and sender: AnyObject?) -> Bool {
        guard let segueID = identifier, let dest = Destination(rawValue: segueID) else {
            return false //
        }
        

        return false
    }
}
