//
//  LabelboxViewModelImpl.swift
//  ProtonMail - Created on 8/15/15.
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
import CoreData

class LabelboxViewModelImpl : MailboxViewModel {
    private let label : Label
    init(label : Label, service: MessageDataService, pushService: PushNotificationService) {
        self.label = label
        super.init(labelID: self.label.labelID, msgService: service, pushService: pushService)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let labelID = try container.decode(String.self, forKey: .labelID)
        guard let label = Label.labelForLableID(labelID, inManagedObjectContext: sharedCoreDataService.mainManagedObjectContext) else {
            throw Errors.decoding
        }
        self.label = label
        try super.init(from: decoder)
    }
    
    override func showLocation () -> Bool {
        return true
    }
    
    override func ignoredLocationTitle() -> String {
        return self.label.exclusive ? self.label.name : ""
    }
    
    override var localizedNavigationTitle: String {
        return self.label.name
    }
    
    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        return action.description;
    }
    
    open override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        if action == .trash || action == .spam {
            return false
        }
        return true
    }
    
    override func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        if let fLabel = message.firstValidFolder() {
            if messageService.move(message: message, from: fLabel, to: Message.Location.trash.rawValue) {
                if self.label.labelID != fLabel {
                    return (.showGeneral, nil)
                }
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.trash.rawValue))
            }
        }
        
        return (.nothing, nil)
    }
    
    override func archive(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(message: message, from: fLabel, to: Message.Location.archive.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.archive.rawValue))
                }
            }
        }
        return (.nothing, nil)
    }
    
    override func spam(index: IndexPath) -> (SwipeResponse, UndoMessage?) {
        if let message = self.item(index: index) {
            if let fLabel = message.firstValidFolder() {
                if messageService.move(message: message, from: fLabel, to: Message.Location.spam.rawValue) {
                    if self.label.labelID != fLabel {
                        return (.showGeneral, nil)
                    }
                    return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: fLabel, newLabels: Message.Location.spam.rawValue))
                }
            }
        }
        return (.nothing, nil)
    }
  
}
