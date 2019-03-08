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
        let childController = self.controller.storyboard?.make(MessageHeaderViewController.self)
        childController?.set(viewModel: MessageHeaderViewModel())
        return childController!
    }()
    
    private lazy var bodyController: MessageBodyViewController = {
        let childController =  self.controller.storyboard?.make(MessageBodyViewController.self)
        let childViewModel = MessageBodyViewModel(contents: WebContents(body: "Loading...", remoteContentMode: .lockdown))
        childController?.set(viewModel: childViewModel)
        childController?.set(coordinator: .init())
        
        return childController!
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
    
    internal func presentBody(onto view: UIView) {
        self.present(self.bodyController, onto: view)
    }
    internal func presentHeader(onto view: UIView) {
        self.present(self.headerController, onto: view)
    }
    
    private func present(_ controller: UIViewController, onto view: UIView) {
        controller.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(controller.view)
        view.topAnchor.constraint(equalTo: controller.view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: controller.view.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor).isActive = true
    }
    
    internal func addChildren(of parent: UIViewController) {
        [self.headerController, self.bodyController].forEach(parent.addChild)
    }
}
