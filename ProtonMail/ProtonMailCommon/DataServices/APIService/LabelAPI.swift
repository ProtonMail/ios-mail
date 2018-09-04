//
//  LabelAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

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
        return LabelAPI.path + AppConstants.DEBUG_OPTION
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
        return LabelAPI.path + AppConstants.DEBUG_OPTION
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
        return LabelAPI.path + "/\(labelID)" + AppConstants.DEBUG_OPTION
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
        return LabelAPI.path + "/\(labelID)" + AppConstants.DEBUG_OPTION
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


