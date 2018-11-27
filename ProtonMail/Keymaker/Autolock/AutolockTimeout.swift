//
//  AutolockTimeout.swift
//  Keymaker
//
//  Created by Anatoly Rosencrantz on 23/10/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

public enum AutolockTimeout: RawRepresentable {
    case never
    case always
    case minutes(Int)
    
    public init(rawValue: Int) {
        switch rawValue {
        case -1: self = .never
        case 0: self = .always
        case let number: self = .minutes(number)
        }
    }
    
    public var rawValue: Int {
        switch self {
        case .never: return -1
        case .always: return 0
        case .minutes(let number): return number
        }
    }
}

