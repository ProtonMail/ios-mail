//
//  PushNotificationServiceSubscription.swift
//  ProtonMail - Created on 08/11/2018.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
        case .reported(let settings):
            try container.encode(settings, forKey: .reported)
        }
    }
}
