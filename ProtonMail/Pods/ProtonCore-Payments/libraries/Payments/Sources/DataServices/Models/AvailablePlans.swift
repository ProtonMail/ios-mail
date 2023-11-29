//
//  AvailablePlans.swift
//  ProtonCorePayments - Created on 13.07.23.
//
//  Copyright (c) 2023 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore. If not, see https://www.gnu.org/licenses/.
//

import Foundation

/// `AvailablePlans` object is the data model for the
/// list of available plans a user can subscribe to.
public struct AvailablePlans: Decodable, Equatable {
    public var plans: [AvailablePlan]
    public var defaultCycle: Int?
    
    public struct AvailablePlan: Decodable, Equatable {
        public var ID: String?
        public var type: Int?
        public var name: String?
        public var title: String
        public var description: String?
        public var instances: [Instance]
        public var entitlements: [Entitlement]
        public var decorations: [Decoration]

        public init(ID: String?, type: Int?, name: String?, title: String, description: String? = nil,
                    instances: [Instance], entitlements: [Entitlement], decorations: [Decoration]) {
            self.ID = ID
            self.type = type
            self.name = name
            self.title = title
            self.description = description
            self.instances = instances
            self.entitlements = entitlements
            self.decorations = decorations
        }

        public struct Instance: Decodable, Equatable {
            public var cycle: Int // enum: 1, 12, 24
            public var description: String
            var periodEnd: Int
            public var price: [Price]
            public var vendors: Vendors?

            public init(cycle: Int, description: String, periodEnd: Int, price: [Price], vendors: Vendors? = nil) {
                self.cycle = cycle
                self.description = description
                self.periodEnd = periodEnd
                self.price = price
                self.vendors = vendors
            }

            public struct Price: Decodable, Equatable {
                public var ID: String
                public var current: Int
                public var currency: String

                public init(ID: String, current: Int, currency: String) {
                    self.ID = ID
                    self.current = current
                    self.currency = currency
                }
            }
            
            public struct Vendors: Decodable, Equatable {
                public var apple: Vendor
                
                public struct Vendor: Decodable, Equatable {
                    public var productID: String
                }
            }
        }
        
        public enum Entitlement: Equatable {
            case description(DescriptionEntitlement)
            
            public struct DescriptionEntitlement: Decodable, Equatable {
                var type: String
                public var iconName: String
                public var text: String
                public var hint: String?
            }
        }
        
        public enum Decoration: Equatable {
            case border(BorderDecoration)
            case starred(StarDecoration)
            case badge(BadgeDecoration)
            
            public struct BorderDecoration: Decodable, Equatable {
                var type: String
                public var color: String
            }
            
            public struct StarDecoration: Decodable, Equatable {
                var type: String
                public var iconName: String
            }
            
            public struct BadgeDecoration: Decodable, Equatable {
                var type: String
                public var anchor: Anchor
                public var text: String
                public var planID: String?
                
                public enum Anchor: String, Decodable, Equatable {
                    case subtitle
                    case title
                }
            }
        }
    }
}

extension AvailablePlans.AvailablePlan.Entitlement: Decodable {
    private enum EntitlementType: String, Decodable {
        case description
    }
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(EntitlementType.self, forKey: .type)
        
        switch type {
        case .description:
            self = .description(try .init(from: decoder))
        }
    }
}

extension AvailablePlans.AvailablePlan.Decoration: Decodable {
    private enum EntitlementType: String, Decodable {
        case border
        case starred
        case badge
    }
    
    enum CodingKeys: String, CodingKey {
        case type
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let type = try container.decode(EntitlementType.self, forKey: .type)
        
        switch type {
        case .border:
            self = .border(try .init(from: decoder))
        case .starred:
            self = .starred(try .init(from: decoder))
        case .badge:
            self = .badge(try .init(from: decoder))
        }
    }
}

extension AvailablePlans.AvailablePlan {
    public var isFreePlan: Bool {
        type == nil
    }
}
