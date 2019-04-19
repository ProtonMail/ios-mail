//
//  ShareUnlockCoordinator.swift
//  Share - Created on 10/31/18.
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

class ShareUnlockCoordinator : PushCoordinator {
    var destinationNavigationController: UINavigationController?
    
    typealias VC = ShareUnlockViewController
    
    var viewController: ShareUnlockViewController?
    private var nextCoordinator: CoordinatorNew?
    
    internal weak var navigationController: UINavigationController?
    var services: ServiceFactory
    
    lazy var configuration: ((ShareUnlockViewController) -> ())? = { vc in
    }
    
    enum Destination : String {
        case pin = "pin"
        case composer = "composer"
    }
    
    deinit {
        print("deinit ShareUnlockCoordinator")
    }
    
    init(navigation : UINavigationController?, services: ServiceFactory) {
        print("init ShareUnlockCoordinator")
        //parent navigation
        self.navigationController = navigation
        self.services = services
        //create self view controller
        self.viewController = ShareUnlockViewController(nibName: "ShareUnlockViewController" , bundle: nil)
    }

    
    private func goPin() {
        //UI refe
        guard let navigationController = self.navigationController else { return }
        self.viewController?.pinUnlock.isEnabled = false
        let pinView = SharePinUnlockCoordinator(navigation: navigationController,
                                                vm: ShareUnlockPinCodeModelImpl(),
                                                services: self.services,
                                                delegate: self)
        self.nextCoordinator = pinView
        pinView.start()
    }
    
    private func gotoComposer() {
        guard let vc = self.viewController,
            let navigationController = self.navigationController else
        {
            return
        }
        
        let viewModel = ContainableComposeViewModel(subject: vc.inputSubject, body: vc.inputContent, files: vc.files, action: .newDraftFromShare)
        let next = UIStoryboard(name: "Composer", bundle: nil).make(ComposeContainerViewController.self)
        next.set(viewModel: ComposeContainerViewModel(editorViewModel: viewModel))
        next.set(coordinator: ComposeContainerViewCoordinator(controller: next, services: self.services))
        navigationController.setViewControllers([next], animated: true)
    }
    
    func go(dest: Destination) {
        switch dest {
        case .pin:
            self.goPin()
        case .composer:
            self.gotoComposer()
        }
    }
}

extension ShareUnlockCoordinator : SharePinUnlockViewControllerDelegate {
    func cancel() {
        self.viewController?.loginCheck()
    }
    
    func next() {
        self.viewController?.signInIfRememberedCredentials()
    }
    
    func failed() {
        
    }
    
    
}
