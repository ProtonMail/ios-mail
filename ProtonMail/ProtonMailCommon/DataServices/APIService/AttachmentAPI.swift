//
//  AttachmentAPI.swift
//  ProtonMail - Created on 10/19/15.
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

// MARK : delete attachment from a draft
final class DeleteAttachment : ApiRequest<ApiResponse> {
    let attachmentID : String!
    init(attID : String) {
        self.attachmentID = attID
    }
    
    convenience init(attID: String, authCredential: AuthCredential?) {
        self.init(attID: attID)
        self.authCredential = authCredential
    }
    
    override func path() -> String {
        //return AttachmentAPI.path + "/remove" + AppConstants.DEBUG_OPTION
        return AttachmentAPI.path + "/" + self.attachmentID + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return AttachmentAPI.v_del_attachment
    }
    
    override func method() -> HTTPMethod {
        return .delete
    }
}


