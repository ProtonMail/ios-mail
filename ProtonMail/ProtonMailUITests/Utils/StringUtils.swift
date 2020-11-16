//
//  StringUtils.swift
//  ProtonMailUITests
//
//  Created by denys zelenchuk on 09.09.20.
//  Copyright © 2020 ProtonMail. All rights reserved.
//

import Foundation


extension String {
    
    func replaceSpaces() -> String {
        return self.replacingOccurrences(of: " ", with: "_")
    }
}
