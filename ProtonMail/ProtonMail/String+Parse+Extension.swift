//
//  StringExtension.swift
//  ProtonMail
//
//  Created by Diego Santiviago on 2/23/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

extension String {
    
    func parseObjectAny () -> [String:Any]? {
        if self.isEmpty {
            return nil
        }
        do {
            let data : Data! = self.data(using: String.Encoding.utf8)
            let decoded = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers) as? [String:Any]
            return decoded
        } catch let ex as NSError {
            PMLog.D("\(ex)")
        }
        return nil
    }
    
}
