//
//  ExclusiveLabel.swift
//  ProtonMail - Created on 12/6/18.
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

enum ExclusiveLabel : String {
    case inbox   = "0"
    case draft   = "1"
    case sent    = "2"
    case starred = "10"
    case archive = "6"
    case spam    = "4"
    case trash   = "3"
    case allmail = "5"
    
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
//            case .deleted:
//                return LocalString._locations_deleted_action
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
}
