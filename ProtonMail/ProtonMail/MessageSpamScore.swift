//
//  MessageSpamScore.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/12/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation



public enum MessageSpamScore: Int, CustomStringConvertible {
    case spam_100 = 100
    case spam_101 = 101
    case others = 0

    public var description : String {
        get {
            switch(self) {
            case .spam_100:
                return NSLocalizedString("This email seems to be from a ProtonMail address but came from outside our system and failed our authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
            case .spam_101:
                return NSLocalizedString("This email has failed its domain's authentication requirements. It may be spoofed or improperly forwarded!", comment: "spam score warning")
            case .others:
                return NSLocalizedString("", comment: "")
            }
        }
    }
}
