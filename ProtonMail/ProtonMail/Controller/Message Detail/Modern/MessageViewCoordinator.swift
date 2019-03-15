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

class MessageViewCoordinator {
    private weak var controller: MessageViewController!
    
    init(controller: MessageViewController) {
        self.controller = controller
    }
    
    
    // Create controllers
    
    private var headerControllers: [MessageHeaderViewController] = []
    private var bodyControllers: [MessageBodyViewController] = []

    typealias ChildViewModelPack = (head: MessageHeaderViewModel, body: MessageBodyViewModel)
    internal func createChildControllers(with children: [ChildViewModelPack]) {
        self.bodyControllers = []
        self.headerControllers = []
        
        children.forEach { head, body in
            self.headerControllers.append(self.createHeaderController(head))
            self.bodyControllers.append(self.createBodyController(body))
        }
    }
    
    private func createHeaderController(_ childViewModel: MessageHeaderViewModel) -> MessageHeaderViewController {
        guard let childController = self.controller.storyboard?.make(MessageHeaderViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController))
        return childController
    }
    
    private func createBodyController(_ childViewModel: MessageBodyViewModel) -> MessageBodyViewController {
        guard let childController =  self.controller.storyboard?.make(MessageBodyViewController.self) else {
            fatalError("No storyboard for creating MessageBodyViewController")
        }
        childController.set(viewModel: childViewModel)
        childController.set(coordinator: .init(controller: childController, enclosingScroller: self.controller) )
        return childController
    }

    // Embed subviews
    
    internal func embedBody(index: Int, onto view: UIView) {
        self.embed(self.bodyControllers[index], onto: view)
    }
    internal func embedHeader(index: Int, onto view: UIView) {
        self.embed(self.headerControllers[index], onto: view)
    }
    
    private func embed(_ child: UIViewController, onto view: UIView) {
        assert(self.controller.isViewLoaded, "Attempt to embed child VC before parent's view was loaded - will cause glitches")
        
        // remove child from old parent
        if let parent = child.parent, parent != self.controller {
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
}


extension MessageViewCoordinator: CoordinatorNew {
    func start() {
        // ?
    }
}
