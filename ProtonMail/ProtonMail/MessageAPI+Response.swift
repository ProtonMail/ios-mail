//
//  MessageAPI+Response.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

final class MessageCountResponse : ApiResponse {
    var counts : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.counts = response?["Counts"] as? [[String : Any]]
        return true
    }
}

final class MessageResponse : ApiResponse {
    var message : [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.message = response?["Message"] as? [String : Any]
        return true
    }
}

