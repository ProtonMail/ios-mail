//
//  File.swift
//  
//
//  Created by xavi on 25/4/24.
//

import SwiftUI

public extension DS.Images {
    static let mailProductLogo = image(named: "mail-product-logo")
}

private extension DS.Images {
    static func image(named: String) -> UIImage {
        UIImage(named: named, in: .module, with: nil)!
    }
}
