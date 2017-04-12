//
//  NSStringExtension.swift
//  ProtonMail
//
//
// Copyright 2015 ArcTouch, Inc.
// All rights reserved.
//
// This file, its contents, concepts, methods, behavior, and operation
// (collectively the "Software") are protected by trade secret, patent,
// and copyright laws. The use of the Software is governed by a license
// agreement. Disclosure of the Software to third parties, in any form,
// in whole or in part, is expressly prohibited except as authorized by
// the license agreement.
//

import Foundation

extension NSString {
    
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded:self as String, options: NSData.Base64DecodingOptions(rawValue: 0)) {
            return String(data: data, encoding: .utf8) ?? ""
        }
        return nil
    }
    
    func base64Encoded() -> String? {
        return data(using: String.Encoding.utf8.rawValue)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
