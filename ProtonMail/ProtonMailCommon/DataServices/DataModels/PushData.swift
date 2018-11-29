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
    
    private enum CodingKeys: String, CodingKey {
        case name = "Name"
        case address = "Address"
    }
}

public struct PushData: Codable {
    let title: String
    let subtitle: String
    let body: String
    let sender: SenderData
    let vibrate: Int
    let sound: Int
    let largeIcon: String
    let smallIcon: String
    let badge: Int
    let messageId: String
    
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
    let type: String
    let version: Int
}
