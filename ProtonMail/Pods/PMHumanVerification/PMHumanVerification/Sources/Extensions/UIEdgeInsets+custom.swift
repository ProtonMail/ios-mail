//
//  UIEdgeInsets+custom.swift
//  PMHumanVerification
//
//  Created by Greg on 06.11.20.
//

#if canImport(UIKit)
import UIKit

public extension UIEdgeInsets {
    static var baner: UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 24, bottom: .infinity, right: 24)
    }

    static var saveAreaBottom: CGFloat {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0
    }
}
#endif
