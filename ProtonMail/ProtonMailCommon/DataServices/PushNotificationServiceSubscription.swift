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
    enum SubscriptionState: String, Codable {
        case notReported, pending, reported
    }
    
    class SubscriptionsPack {
        init(_ subSaver: Saver<Set<SubscriptionWithSettings>>,
             _ encSaver: Saver<Set<SubscriptionSettings>>,
             _ outSaver: Saver<Set<SubscriptionSettings>>)
        {
            self.subscriptionSaver = subSaver
            self.encryptionKitSaver = encSaver
            self.outdatedSaver = outSaver
        }
        private let subscriptionSaver: Saver<Set<SubscriptionWithSettings>>
        internal let encryptionKitSaver: Saver<Set<SubscriptionSettings>>
        private let outdatedSaver: Saver<Set<SubscriptionSettings>>
        
        private(set) var subscriptions: Set<SubscriptionWithSettings> {
            get { return self.subscriptionSaver.get() ?? Set([])  }
            set {
                self.subscriptionSaver.set(newValue: newValue) // in keychain cuz should persist over reinstalls
                
                let reportedSettings: [SubscriptionSettings] = newValue.compactMap { $0.state == .reported ? $0.settings : nil}
                self.encryptionKitSaver.set(newValue: Set(reportedSettings))
            }
        }
        
        private(set) var outdatedSettings: Set<SubscriptionSettings> {
            get { return self.outdatedSaver.get() ?? [] } // cuz PushNotificationDecryptor can add values to this colletion while app is running
            set { self.outdatedSaver.set(newValue: newValue) } // in keychain cuz should persist over reinstalls
        }
        
        internal func removed(_ settingsToRemove: SubscriptionSettings) {
            self.outdatedSettings.remove(settingsToRemove)
        }
        internal func outdate(_ settingsToMoveToOutdated: Set<SubscriptionSettings>) {
            let toOutdate = self.subscriptions.filter { settingsToMoveToOutdated.contains($0.settings) }
            self.subscriptions.subtract(toOutdate)
            self.outdatedSettings.formUnion(settingsToMoveToOutdated)
        }
        internal func insert(_ subscriptionsToInsert: Set<SubscriptionWithSettings>) {
            self.subscriptions.formUnion(subscriptionsToInsert)
        }
        internal func update(_ settings: SubscriptionSettings, toState: SubscriptionState) {
            let toReplace = self.subscriptions.filter { $0.settings == settings }
            var updated = self.subscriptions.subtracting(toReplace)
            updated.insert(SubscriptionWithSettings.init(settings: settings, state: toState))
            self.subscriptions = updated
        }
        
        internal func settings() -> Set<SubscriptionSettings> {
            return Set(self.subscriptions.map { $0.settings })
        }
        
        internal func encryptionKit(forUID uid: String) -> EncryptionKit? {
            return self.encryptionKitSaver.get()?.first(where: { $0.UID == uid })?.encryptionKit
        }
    }
    
    class SubscriptionWithSettings: Hashable, Codable, CustomDebugStringConvertible {
        static func == (lhs: PushNotificationService.SubscriptionWithSettings, rhs: PushNotificationService.SubscriptionWithSettings) -> Bool {
            lhs.settings == rhs.settings
        }
        func hash(into hasher: inout Hasher) {
            hasher.combine(self.settings)
        }
        var debugDescription: String {
            return "Settings: \(self.settings.token), \(self.settings.UID), \(self.settings.encryptionKit == nil ? "no encr kit" : "with encr ekit"), State: \(self.state.rawValue)"
        }
        
        var state: SubscriptionState
        private(set) var settings: SubscriptionSettings
        
        fileprivate func applyState(_ newState: SubscriptionState) {
            self.state = newState
        }
        
        init(settings: SubscriptionSettings, state: SubscriptionState) {
            self.state = state
            self.settings = settings
        }
    }
}


extension PushNotificationService {
@available(*, deprecated)
    enum Subscription: Hashable {
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
