//
//  File.swift
//  
//
//  Created by xavi on 21/3/24.
//

import SwiftUI

public extension DS.Font {

    // Font modifier that reacts to dynamic font size changes
    struct Dynamic: ViewModifier {
        /**
         Even if it's not used, declaring the `sizeCategory` environment variable will make the
         view update when the dynamic font type is changed.
         */
        @Environment(\.sizeCategory) var sizeCategory
        var size: CGFloat

        public func body(content: Content) -> some View {
            let scaledSize = UIFontMetrics.default.scaledValue(for: size)
            return content.font(.system(size: scaledSize))
        }
    }
}

public extension View {
    func fontBody3() -> some View {
        return self.modifier(DS.Font.Dynamic(size: 14))
    }
}
