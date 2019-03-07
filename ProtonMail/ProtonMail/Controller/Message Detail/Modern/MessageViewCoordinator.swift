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
    
    private lazy var bodyController: MessageBodyViewController = {
        let newBodyController =  self.controller?.storyboard?.make(MessageBodyViewController.self)
        
        let childViewModel = MessageBodyViewModel(contents: WebContents(body: "Loading...", remoteContentMode: .lockdown))
        newBodyController?.set(viewModel: childViewModel)
        newBodyController?.set(coordinator: .init())
        
        return newBodyController!
    }()
    
    func start() {
        // ?
    }
    
    func updateBody(viewModel: MessageBodyViewModel) {
        self.bodyController.set(viewModel: viewModel)
    }
    
    func presentBody(onto view: UIView) {
        view.addSubview(self.bodyController.view)
        view.topAnchor.constraint(equalTo: self.bodyController.view.topAnchor).isActive = true
        view.bottomAnchor.constraint(equalTo: self.bodyController.view.bottomAnchor).isActive = true
        view.leadingAnchor.constraint(equalTo: self.bodyController.view.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: self.bodyController.view.trailingAnchor).isActive = true
    }
    
    func addChildren(of parent: UIViewController) {
        parent.addChild(self.bodyController)
    }
}
