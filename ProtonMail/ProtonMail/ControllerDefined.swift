//
//  ControllerConstants.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

//MARK : Compose view controller
public struct EncryptionStep {
    static let DefinePassword = "DefinePassword"
    static let ConfirmPassword = "ConfirmPassword"
    static let DefineHintPassword = "DefineHintPassword"
}

enum ComposeMessageAction: Int, CustomStringConvertible {
    case reply = 0
    case replyAll = 1
    case forward = 2
    case newDraft = 3
    case openDraft = 4
    
    var description : String {
        get {
            switch(self) {
            case .reply:
                return NSLocalizedString("Reply", comment: "Action")
            case .replyAll:
                return NSLocalizedString("ReplyAll", comment: "Action")
            case .forward:
                return NSLocalizedString("Forward", comment: "Action")
            case .newDraft:
                return NSLocalizedString("Draft", comment: "Action")
            case .openDraft:
                return NSLocalizedString("OpenDraft", comment: "Action")
            }
        }
    }
}
