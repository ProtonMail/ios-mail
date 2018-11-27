//
//  PushNotificationServiceSubscription.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 08/11/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

extension PushNotificationService {
    enum Subscription {
        /// no subscription locally. NOT persisted via Codable
        case none
        
        /// not sent to BE yet. NOT persisted via Codable
        case notReported(SubscriptionSettings)
        
        /// not on BE yet, but sending started. NOT persisted via Codable
        case pending(SubscriptionSettings)
        
        /// this is on BE. Will be persisted via Codable
        case reported(SubscriptionSettings)
    }
}

extension PushNotificationService.Subscription: Equatable {
    // i just hope it is inferred correctly
}

extension PushNotificationService.Subscription: Codable {
    internal enum CodingKeys: CodingKey {
        case reported
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let settings =  try? container.decode(PushNotificationService.SubscriptionSettings.self, forKey: .reported) {
            self = .reported(settings)
            return
        }
        
        self = .none
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .none, .pending, .notReported: break // no sence in saving these values - settings not accepted by BE are useless
        case .reported(let settings): try container.encode(settings, forKey: .reported)
        }
    }
}
