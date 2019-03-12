//
//  MessageViewCoordinator.swift
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

class MessageViewCoordinator: CoordinatorNew {
    private weak var controller: MessageViewController!
    
    init(controller: MessageViewController) {
        self.controller = controller
    }
    
    private lazy var headerController: MessageHeaderViewController = {
        guard let childController = self.controller.storyboard?.make(MessageHeaderViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        childController.set(viewModel: MessageHeaderViewModel())
        return childController
    }()
    
    private lazy var bodyController: MessageBodyViewController = {
        guard let childController =  self.controller.storyboard?.make(MessageBodyViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        let childViewModel = MessageBodyViewModel(contents: WebContents(body: "Loading...", remoteContentMode: .lockdown))
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController, enclosingScroller: self.controller) )
        return childController
    }()
    
    func start() {
        // ?
    }
    
    internal func updateBody(viewModel: MessageBodyViewModel) {
        self.bodyController.set(viewModel: viewModel)
    }
    internal func updateHeader(viewModel: MessageHeaderViewModel) {
        self.headerController.set(viewModel: viewModel)
    }
    
    internal func embedBody(onto view: UIView) {
        self.embed(self.bodyController, onto: view)
    }
    internal func embedHeader(onto view: UIView) {
        self.embed(self.headerController, onto: view)
    }
    
    private func embed(_ child: UIViewController, onto view: UIView) {
        assert(self.controller.isViewLoaded, "Attempt to embed child VC before parent's view was loaded - will cause glitches")
        
        // remove child from old parent
        if let _ = child.parent {
            child.willMove(toParent: nil)
            if child.isViewLoaded {
                child.view.removeFromSuperview()
            }
            child.removeFromParent()
        }
        
        // add child to new parent
        self.controller.addChild(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view) 
        child.didMove(toParent: self.controller)
        
        // autolayout
        view.topAnchor.constraint(equalTo: child.view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: child.view.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: child.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: child.view.trailingAnchor).isActive = true
    }
    
    internal func addChildren(of parent: UIViewController) {

    }
}
