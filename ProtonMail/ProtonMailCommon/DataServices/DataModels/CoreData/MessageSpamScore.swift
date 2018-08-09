//
//  MessageSpamScore.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/12/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



enum MessageSpamScore: Int, CustomStringConvertible {
    case spam_100 = 100
    case spam_101 = 101
    case spam_102 = 102
    case others = 0

    var description : String {
        get {
            switch(self) {
            case .spam_100:
                return LocalString._messages_spam_100_warning
            case .spam_101:
                return LocalString._messages_spam_101_warning
            case .spam_102:
                return LocalString._messages_spam_102_warning
            case .others:
                return ""
            }
        }
    }
}
