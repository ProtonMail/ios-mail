//
//  PaymentMethod.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 31/08/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

struct PaymentMethod: Codable {
    enum PaymentType: String, Codable {
        case other = "other"
        case apple = "apple"
        case card = "card"
        
        init?(rawValue: String) {
            if rawValue == PaymentType.apple.rawValue {
                self = .apple
            } else if rawValue == PaymentType.card.rawValue {
                self = .card
            } else {
                self = .other
            }
        }
    }
    
    let iD: String
    let type: PaymentType
}
