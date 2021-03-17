//
//  Common.swift
//  PMCoreTranslation
//
//  Created by Greg on 07.11.20.
//

import Foundation

class Common {
    public static var bundle: Bundle {
        return Bundle(path: Bundle(for: Common.self).path(forResource: "Resources-Translation", ofType: "bundle")!)!
    }
}
