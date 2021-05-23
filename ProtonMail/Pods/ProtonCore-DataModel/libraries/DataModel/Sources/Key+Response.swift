//
//  Key+Response.swift
//  ProtonCore-DataModel - Created on 4/19/21.
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.
//

import Foundation

extension Key {
    
    /// Initializes the Key with the response data [String:Any]
    public convenience init(response: [String: Any]) {
        self.init(keyID: response["ID"] as? String ?? "",
                  privateKey: response["PrivateKey"] as? String,
                  token: response["Token"] as? String,
                  signature: response["Signature"] as? String,
                  activation: response["Activation"] as? String)
    }
}
