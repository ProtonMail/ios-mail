//
//  UIImageExtension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/14/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation


extension UIImage {

    class func image(with color: UIColor) -> UIImage? {
        let rect = CGRect(x: 0.0, y: 0.0, width: 1.0, height: 1.0)
        UIGraphicsBeginImageContext(rect.size)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(color.cgColor)
            context.fill(rect)
        }
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
