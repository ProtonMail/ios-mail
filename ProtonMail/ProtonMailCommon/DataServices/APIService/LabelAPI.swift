//
//  LabelAPI.swift
//  ProtonMail - Created on 8/13/15.
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


/// Get user's labels/contact groups in the order to be displayed from the server
final class GetLabelsRequest : ApiRequest<GetLabelsResponse> {
    var type: Int = 1
    init(type: Int = 1) {
        self.type = type
    }
    
    override func toDictionary() -> [String : Any]? {
        return ["Type" : type]
    }
    
    override func path() -> String {
        return LabelAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.v_get_user_labels
    }
}

/// Parse the response from the server of the GetLabelsRequest() call
final class GetLabelsResponse : ApiResponse {
    var labels : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.labels =  response["Labels"] as? [[String : Any]]
        return true
    }
}

/// Create a label/contact group on the server
final class CreateLabelRequest<T : ApiResponse> : ApiRequest<T> {
    var labelName: String
    var color: String
    var exclusive: Bool = false
    var type: Int = 1
    
    init(name: String, color: String, exclusive: Bool = false, type: Int = 1) {
        self.labelName = name
        self.color = color
        self.exclusive = exclusive
        self.type = type
    }
    
    override func toDictionary() -> [String : Any]? {
        
        var out : [String : Any] = [
            "Name": self.labelName,
            "Color": self.color,
            "Display": type == 1 ? 0 : 1, /* Don't show the contact group on the side bar */
            "Type": self.type,
        ]
        
        if type == 1 {
            out["Exclusive"] = self.exclusive ? 1 : 0
        }

        return out
    }
    
    override func method() -> HTTPMethod {
        return .post
    }
    
    override func path() -> String {
        return LabelAPI.path + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.v_create_label
    }
}

/// Parse the response from the server of the GetLabelsRequest() call
final class CreateLabelRequestResponse : ApiResponse {
    var label:[String : Any]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.label = response["Label"] as? [String : Any]
        return true
    }
}

/**
 Update the data of a label/contact group on the server
 
 Type don't need to be specified here since we have the exact labelID to work with
*/
final class UpdateLabelRequest : ApiRequest<CreateLabelRequestResponse> {
    var labelID : String
    var labelName: String
    var color:String
    
    init(id:String, name:String, color:String) {
        self.labelID = id
        self.labelName = name
        self.color = color
    }
    
    override func toDictionary() -> [String : Any]? {
        let out : [String : Any] = [
            "Name": self.labelName,
            "Color": self.color,
            "Display": 0
        ]
        return out
    }
    
    override func method() -> HTTPMethod {
        return .put
    }
    
    override func path() -> String {
        return LabelAPI.path + "/\(labelID)" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.v_update_label
    }
}

/// Parse the response from the server of the UpdateLabelRequest() call
final class UpdateLabelRequestResponse: ApiResponse {
    var label: [String : Any]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.label = response["Label"] as? [String : Any]
        return true
    }
}

/**
 Delete a contact group on the server
 
 Type don't need to be specified here since we have the exact labelID to work with
*/
final class DeleteLabelRequest<T : ApiResponse> : ApiRequest<T> {
    var labelID: String
    
    init(lable_id: String) {
        labelID = lable_id
    }
    
    override func method() -> HTTPMethod {
        return .delete
    }
    
    override func path() -> String {
        return LabelAPI.path + "/\(labelID)" + Constants.App.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.v_delete_label
    }
}

/// Parse the response from the server of the DeleteLabelRequest() call
final class DeleteLabelRequestResponse: ApiResponse {
    var returnedCode: Int?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.returnedCode = response["Code"] as? Int
        return true
    }
}


