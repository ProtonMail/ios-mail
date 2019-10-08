//
//  MailboxViewModelImpl.swift
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

final class MailboxViewModelImpl : MailboxViewModel {

    private let label : Message.Location

    init(label : Message.Location, service: MessageDataService, pushService: PushNotificationService) {
        self.label = label
        super.init(labelID: label.rawValue, msgService: service, pushService: pushService)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let labelID = try container.decode(String.self, forKey: .labelID)
        guard let label = Message.Location(rawValue: labelID) else {
            throw Errors.decoding
        }
        self.label = label
        try super.init(from: decoder)
    }
    
    override var localizedNavigationTitle: String {
        return self.label.localizedTitle
    }

    override func getSwipeTitle(_ action: MessageSwipeAction) -> String {
        switch(self.label) {
        case .trash, .spam:
            if action == .trash {
                return LocalString._general_delete_action
            }
            return action.description
        default:
            return action.description
        }
    }

    override func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
        switch(self.label) {
        case .archive:
            return action != .archive
        case .starred:
            return action != .star
        case .spam:
            return action != .spam
        case .draft:
            return action != .spam && action != .trash && action != .archive
        case .sent:
            return action != .spam
        case .trash:
            return action != .trash
        case .allmail:
            return false
        default:
            return true
        }
    }
    
    override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
        switch(self.label) {
        case .starred:
            return true
        default:
            return false
        }
    }
    
    override func isDrafts() -> Bool {
        return self.label == .draft
    }
    
    override func isArchive() -> Bool {
        return self.label == .archive
    }
    
    override func isDelete () -> Bool {
        switch(self.label) {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }
    
    override func showLocation() -> Bool {
        switch(self.label) {
        case .allmail, .sent, .trash, .archive, .draft:
            return true
        default:
            return false
        }
    }
    
    override func isShowEmptyFolder() -> Bool {
        switch(self.label) {
        case .trash, .spam, .draft:
            return true
        default:
            return false
        }
    }
    
    override func emptyFolder() {
        switch(self.label) {
        case .trash, .spam, .draft:
            sharedMessageDataService.empty(location: self.label)
        default:
            break
        }
    }
    
    
    override func ignoredLocationTitle() -> String {
        if self.label == .sent {
            return Message.Location.sent.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        if self.label == .archive {
            return Message.Location.archive.title
        }
        if self.label == .draft {
            return Message.Location.draft.title
        }
        if self.label == .trash {
            return Message.Location.trash.title
        }
        return ""
    }
    
    override func reloadTable() -> Bool {
        return self.label == .draft
    }
    
    override func delete(message: Message) -> (SwipeResponse, UndoMessage?) {
        switch(self.label) {
        case .trash, .spam, .draft:
            if messageService.delete(message: message, label: self.label.rawValue) {
                return (.showGeneral, nil)
            }
        default:
            if messageService.move(message: message, from: self.label.rawValue, to: Message.Location.trash.rawValue) {
                return (.showUndo, UndoMessage(msgID: message.messageID, origLabels: self.label.rawValue, newLabels: Message.Location.trash.rawValue))
            }
        }
        
        return (.nothing, nil)
    }
    

}
