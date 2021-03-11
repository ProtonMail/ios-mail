//
//  Data+Extensions.swift
//  PMAuthentication
//
//  Created by Igor Kulman on 21.12.2020.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation

extension Data {
    func encodeBase64() -> String {
        return self.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
    }
}
