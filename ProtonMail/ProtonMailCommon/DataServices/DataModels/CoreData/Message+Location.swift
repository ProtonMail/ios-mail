//
//  MessageLocation.swift
//  ProtonMail
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

extension Message {
    
    enum HidenLocation : String {
        case draft = "1" //1 can't be removed
        case sent  = "2" //2 can't be removed
    }
    
    /// Predefined location. matches with exclusive lable id
    enum Location : String {
        case inbox   = "0"
        case draft   = "8"  //"8"   //1 can't be removed
        case sent    = "7"  //"7"    //2 can't be removed
        case starred = "10"
        case archive = "6"
        case spam    = "4"
        case trash   = "3"
        case allmail = "5"
        //8 , 7  another type of draft,sent
        var localizedTitle : String {
            switch(self) {
            case .inbox:
                return LocalString._locations_inbox_title
            case .starred:
                return LocalString._locations_starred_title
            case .draft:
                return LocalString._locations_draft_title
            case .sent:
                return LocalString._locations_outbox_title
            case .trash:
                return LocalString._locations_trash_title
            case .archive:
                return LocalString._locations_archive_title
            case .spam:
                return LocalString._locations_spam_title
            case .allmail:
                return LocalString._locations_all_mail_title
            }
        }
        
        var actionTitle : String {
            get {
                switch(self) {
                case .inbox:
                    return LocalString._locations_move_inbox_action
                case .draft:
                    return LocalString._locations_move_draft_action
                case .sent:
                    return LocalString._locations_move_outbox_action
                case .spam:
                    return LocalString._locations_move_spam_action
                case .starred:
                    return LocalString._locations_add_star_action
                case .archive:
                    return LocalString._locations_move_archive_action
                case .trash:
                    return LocalString._locations_move_trash_action
                case .allmail:
                    return LocalString._locations_move_allmail_action
                }
            }
        }
        
        public var title : String {
            switch(self) {
            case .inbox:
                return LocalString._locations_inbox_title
            case .starred:
                return LocalString._locations_starred_title
            case .draft:
                return LocalString._locations_draft_title
            case .sent:
                return LocalString._locations_outbox_title
            case .trash:
                return LocalString._locations_trash_title
            case .archive:
                return LocalString._locations_archive_title
            case .spam:
                return LocalString._locations_spam_title
            case .allmail:
                return LocalString._locations_all_mail_title
            }
        }
    }
}

//public enum MessageLocation: Int, CustomStringConvertible {
//    case deleted = -1
//    case draft = 1
//    case inbox = 0
//    case outbox = 2
//    case spam = 4
//    case archive = 6
//    case trash = 3
//    case allmail = 5
//    case starred = 10
//
//    //8 , 7  another type of draft,sent
//    public var actionTitle : String {
//        get {
//            switch(self) {
//            case .deleted:
//                return LocalString._locations_deleted_action
//            case .inbox:
//                return LocalString._locations_move_inbox_action
//            case .draft:
//                return LocalString._locations_move_draft_action
//            case .outbox:
//                return LocalString._locations_move_outbox_action
//            case .spam:
//                return LocalString._locations_move_spam_action
//            case .starred:
//                return LocalString._locations_add_star_action
//            case .archive:
//                return LocalString._locations_move_archive_action
//            case .trash:
//                return LocalString._locations_move_trash_action
//            case .allmail:
//                return LocalString._locations_move_allmail_action
//            }
//        }
//    }
//
//    public var description : String {
//        get {
//            switch(self) {
//            case .deleted:
//                return LocalString._locations_deleted_desc
//            case .inbox:
//                return LocalString._locations_inbox_desc
//            case .draft:
//                return LocalString._locations_draft_desc
//            case .outbox:
//                return LocalString._locations_outbox_desc
//            case .spam:
//                return LocalString._locations_spam_desc
//            case .starred:
//                return LocalString._locations_starred_desc
//            case .archive:
//                return LocalString._locations_archive_desc
//            case .trash:
//                return LocalString._locations_trash_desc
//            case .allmail:
//                return LocalString._locations_all_mail_desc
//            }
//        }
//    }
//
//    public var title : String {
//        switch(self) {
//        case .inbox:
//            return LocalString._locations_inbox_title
//        case .starred:
//            return LocalString._locations_starred_title
//        case .draft:
//            return LocalString._locations_draft_title
//        case .outbox:
//            return LocalString._locations_outbox_title
//        case .trash:
//            return LocalString._locations_trash_title
//        case .archive:
//            return LocalString._locations_archive_title
//        case .spam:
//            return LocalString._locations_spam_title
//        case .allmail:
//            return LocalString._locations_all_mail_title
//        default:
//            return LocalString._locations_inbox_title
//        }
//    }
//
//    public var key: String {
//        switch(self) {
//        case .deleted:
//            return "Deleted"
//        case .inbox:
//            return "Inbox"
//        case .draft:
//            return "Draft"
//        case .outbox:
//            return "Outbox"
//        case .spam:
//            return "Spam"
//        case .starred:
//            return "Starred"
//        case .archive:
//            return "Archive"
//        case .trash:
//            return "Trash"
//        case .allmail:
//            return "AllMail"
//        }
//    }
//
//    var moveAction: MessageAction? {
//        switch(self) {
//        case .deleted:
//            return .delete
//        case .inbox:
//            return .inbox
//        case .spam:
//            return .spam
//        case .trash:
//            return .trash
//        case .archive:
//            return .archive
//        default:
//            return nil
//        }
//    }
//}
//
