//
//  MessageAPI+Response.swift
//  ProtonMail - Created on 4/12/18.
//
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


import Foundation
import PMCommon

final class MessageCountResponse : Response {
    var counts : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.counts = response?["Counts"] as? [[String : Any]]
        return true
    }
}

final class MessageResponse : Response {
    var message : [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.message = response?["Message"] as? [String : Any]
        return true
    }
}

final class SearchMessageResponse : Response {
    var jsonDic : [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.jsonDic = response
        return true
    }
}

final class UpdateDraftResponse: Response {
    var responseDict: [String: Any] = [:]
    
    override func ParseResponse(_ response: [String : Any]) -> Bool {
        let result = super.ParseResponse(response)
        if result {
            self.responseDict = response["Message"] as? [String : Any] ?? [:]
        }
        
        return result
    }
}
