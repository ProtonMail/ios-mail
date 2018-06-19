//
//  AppVersion.swift
//  ProtonMail
//
//  Created by Anatoly Rosencrantz on 15/06/2018.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation

struct AppVersion: Comparable, Equatable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        let maxCount: Int = max(lhs.numbers.count, rhs.numbers.count)
        
        func normalizer(_ input: Array<Int>) -> Array<Int> {
            var norm = input
            let zeros = Array<Int>(repeating: 0, count: maxCount - input.count)
            norm.append(contentsOf: zeros)
            return norm
        }
        
        let pairs = zip(normalizer(lhs.numbers), normalizer(rhs.numbers))
        for (l, r) in pairs {
            if l < r {
                return true
            } else if l > r {
                return false
            }
        }
        return false
    }

    private(set) var string: String
    private var numbers: Array<Int>
    
    static var current: AppVersion {
        return .init(Bundle.main.appVersion)
    }
    
    init(_ string: String) {
        self.string = string
        self.numbers = string.split(separator: ".").compactMap { Int($0) }
    }
}
