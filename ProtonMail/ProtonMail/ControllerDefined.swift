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

enum ComposeMessageAction: Int, Printable {
    case Reply = 0
    case ReplyAll = 1
    case Forward = 2
    case NewDraft = 3
    case OpenDraft = 4
    
    var description : String {
        get {
            switch(self) {
            case Reply:
                return NSLocalizedString("Reply")
            case ReplyAll:
                return NSLocalizedString("ReplyAll")
            case Forward:
                return NSLocalizedString("Forward")
            case NewDraft:
                return NSLocalizedString("Draft")
            case OpenDraft:
                return NSLocalizedString("OpenDraft")
            }
        }
    }
}