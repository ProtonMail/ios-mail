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

    init(label : Message.Location, service: MessageDataService) {
        self.label = label
        super.init(labelID: label.rawValue, msgService: service)
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
            return action.description;
        default:
            return action.description;
        }
    }

//    override func isSwipeActionValid(_ action: MessageSwipeAction) -> Bool {
//        switch(self.location!) {
//        case .archive:
//            return action != .archive
//        case .starred:
//            return action != .star
//        case .spam:
//            return action != .spam
//        case .draft, .outbox:
//            return action != .spam && action != .trash && action != .archive
//        case .trash:
//            return action != .trash
//        case .allmail:
//            return false;
//        default:
//            return true
//        }
//    }
//
//    override func stayAfterAction (_ action: MessageSwipeAction) -> Bool {
//        switch(self.location!) {
//        case .starred:
//            return true
//        default:
//            return false
//        }
//    }
//
//    override func deleteMessage(_ msg: Message) -> SwipeResponse  {
//        var needShowMessage = true
//        if let context = msg.managedObjectContext {
//            switch(self.location!) {
//            case .trash, .spam:
//                msg.removeLocationFromLabels(currentlocation: self.location, location: .deleted, keepSent: false)
//                msg.needsUpdate = true
//                msg.location = .deleted
//                needShowMessage = false
//            default:
//                msg.removeLocationFromLabels(currentlocation: self.location, location: .trash, keepSent: true)
//                msg.needsUpdate = true
//                self.updateBadgeNumberWhenMove(msg, to: .deleted)
//                msg.location = .trash
//            }
//            context.perform {
//                if let error = context.saveUpstreamIfNeeded() {
//                    PMLog.D("error: \(error)")
//                }
//            }
//        }
//        return needShowMessage ? SwipeResponse.showUndo : SwipeResponse.nothing
//    }
//
//    override func isDrafts() -> Bool {
//        return self.location == MessageLocation.draft
//    }
//
//    override func isArchive() -> Bool {
//        return self.location == MessageLocation.archive
//    }
//
//    override func isDelete () -> Bool {
//        switch(self.location!) {
//        case .trash, .spam, .draft:
//            return true;
//        default:
//            return false
//        }
//    }
//
//    override func showLocation() -> Bool {
//        switch(self.location!) {
//        case .allmail, .outbox, .trash, .archive, .draft:
//            return true
//        default:
//            return false
//        }
//    }

    override func isShowEmptyFolder() -> Bool {
        switch(self.label) {
        case .trash, .spam:
            return true;
        default:
            return false
        }
    }
//
//    override func emptyFolder() {
//        switch(self.location!) {
//        case .trash:
//            sharedMessageDataService.emptyTrash();
//        case .spam:
//            sharedMessageDataService.emptySpam();
//        default:
//            break
//        }
//    }
//
//    override func ignoredLocationTitle() -> String {
//        if self.location == .outbox {
//            return MessageLocation.outbox.title
//        }
//
//        if self.location == .trash {
//            return MessageLocation.trash.title
//        }
//        if self.location == .archive {
//            return MessageLocation.archive.title
//        }
//        if self.location == .draft {
//            return MessageLocation.draft.title
//        }
//        if self.location == .trash {
//            return MessageLocation.trash.title
//        }
//        return ""
//    }



    override func reloadTable() -> Bool {
        return self.label == .draft
    }
}
