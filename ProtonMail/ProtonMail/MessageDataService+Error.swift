//
//  MessageDataService+Error.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


extension MessageDataService {
    enum RuntimeError : String, Error, CustomErrorVar {
        case cant_decrypt = "can't decrypt message body"
        case bad_draft
        var code: Int {
            get {
                return -1002000
            }
        }
        var desc: String {
            get {
                switch self {
                case .bad_draft:
                    return NSLocalizedString("Unable to send the email", comment: "error when sending the message")
                default:
                    break
                }
                return self.rawValue
            }
        }
        var reason: String {
            get {
                switch self {
                case .bad_draft:
                    return NSLocalizedString("The draft format incorrectly sending failed!", comment: "error when sending the message")
                default:
                    break
                }
                return self.rawValue
            }
        }
    }
}
