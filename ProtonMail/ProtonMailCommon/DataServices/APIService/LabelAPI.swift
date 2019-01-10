//
//  LabelAPI.swift
//  ProtonMail - Created on 8/13/15.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


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
            out["Exclusive"] = self.exclusive
        }

        return out
    }
    
    override func method() -> APIService.HTTPMethod {
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
final class UpdateLabelRequest<T: ApiResponse> : ApiRequest<T> {
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
    
    override func method() -> APIService.HTTPMethod {
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
    
    override func method() -> APIService.HTTPMethod {
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


