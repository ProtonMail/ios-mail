//
//  PushNotificationServiceSubscription.swift
//  ProtonMail - Created on 08/11/2018.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
