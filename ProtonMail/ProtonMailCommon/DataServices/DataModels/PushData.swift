//
//  PushData.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

public struct SenderData: Codable {
    let name: String
    let address: String
    // Unused on iOS fields:
    //    let group: Any
    
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
    }
}

public struct PushData: Codable {
    let badge: Int
    let body: String
    let sender: SenderData
    let messageId: String
    // Unused on iOS fields:
    //    let title: String
    //    let subtitle: String
    //    let vibrate: Int
    //    let sound: Int
    //    let largeIcon: String
    //    let smallIcon: String
    
    
    static func parse(with json: String) -> PushData? {
        guard let data = json.data(using: .utf8),
            let push = try? JSONDecoder().decode(Push.self, from: data) else
        {
            return nil
        }
        return push.data
    }
}

public struct Push: Codable {
    let data: PushData
    // Unused on iOS fields
    //    let type: String
    //    let version: Int
}
