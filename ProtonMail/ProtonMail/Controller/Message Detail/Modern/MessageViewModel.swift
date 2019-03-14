//
//  MessageViewModel.swift
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


/// ViewModel object of big MessaveViewController screen with a whole thread of messages inside. ViewModel objects of singular messages are nested in `thread` array.
class MessageViewModel: NSObject {
    private var messages: [Message]
    private var observationsHeader: [NSKeyValueObservation] = []
    private var observationsBody: [NSKeyValueObservation] = []

    // model - viewModel connections
    @objc private(set) dynamic var thread: [Standalone]
    private func message(for standalone: Standalone) -> Message? {
        return self.messages.first(where: { $0.messageID == standalone.messageID })
    }
    
    init(conversation messages: [Message]) {
        self.messages = messages
        self.thread = messages.map(Standalone.init)
    }
    
    init(message: Message) {
        self.messages = [message]
        self.thread = [Standalone(message: message)]
    }
    
    internal func subscribe(toUpdatesOf children: [MessageViewCoordinator.ChildViewModelPack]) {
        self.observationsHeader = []
        self.observationsBody = []
        
        children.enumerated().forEach { index, child in
            let headObservation = child.head.observe(\.contentsHeight) { [weak self] head, _ in
                self?.thread[index].heightOfHeader = head.contentsHeight
            }
            self.observationsHeader.append(headObservation)
            
            let bodyObservation = child.body.observe(\.contentSize) { [weak self] body, _ in
                self?.thread[index].heightOfBody = body.contentSize.height
            }
            self.observationsHeader.append(bodyObservation)
        }
    }
}
