//
//  LabelAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 8/13/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import Foundation

// MARK : Get messages part
final class GetLabelsRequest<T : ApiResponse> : ApiRequest<T> {
    
    override init() {
    }
    
    override func method() -> APIService.HTTPMethod {
        return .get
    }
    
    override open func path() -> String {
        return LabelAPI.Path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_LabelFetchRequest
    }
}

final class GetLabelsResponse : ApiResponse {
    var labels : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.labels =  response["Labels"]  as? [[String : Any]]
        return true
    }
}


// MARK : apply label to message
final class ApplyLabelToMessageRequest<T : ApiResponse> : ApiRequest<T> {
    var labelID: String!
    var messages:[String]!
    
    init(labelID:String!, messages: [String]!) {
        self.labelID = labelID
        self.messages = messages
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["MessageIDs"] = messages
        return out
    }
    
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override open func path() -> String {
        return LabelAPI.Path + "/apply/" + self.labelID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_ApplyLabelToMessageRequest
    }
}

// MARK : remove label from message
final class RemoveLabelFromMessageRequest<T : ApiResponse> : ApiRequest<T> {
    
    var labelID: String!
    var messages:[String]!
    
    init(labelID:String!, messages: [String]!) {
        self.labelID = labelID
        self.messages = messages
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["MessageIDs"] = messages
        //PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
    
    override open func path() -> String {
        return LabelAPI.Path + "/remove/" + self.labelID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_RemoveLabelFromMessageRequest
    }
}


// MARK : create label
final class CreateLabelRequest<T : ApiResponse> : ApiRequest<T> {
    var labelName: String
    var color:String
    var exclusive : Bool = false
    
    init(name:String, color:String, exclusive : Bool) {
        self.labelName = name
        self.color = color
        self.exclusive = exclusive
    }
    
    override func toDictionary() -> [String : Any]? {
        
        let out : [String : Any] = [
            "Name": self.labelName,
            "Color": self.color,
            "Display": 0,
            "Exclusive" : self.exclusive
        ]

        return out
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
    
    override open func path() -> String {
        return LabelAPI.Path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_CreateLabelRequest
    }
}


// MARK : update label
final class UpdateLabelRequest<T : ApiResponse> : ApiRequest<T> {
    
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
    
    override open func path() -> String {
        return LabelAPI.Path + "/\(labelID)" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_UpdateLabelRequest
    }
}

final class CreateLabelRequestResponse : ApiResponse {
    var label:[String : Any]?
    
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.label = response["Label"] as? [String : Any]
        return true
    }
}


// MARK : create label
final class DeleteLabelRequest<T : ApiResponse> : ApiRequest<T> {
    
    var labelID: String
    
    init(lable_id: String) {
        labelID = lable_id
    }
    
    override func method() -> APIService.HTTPMethod {
        return .delete
    }
    
    override open func path() -> String {
        return LabelAPI.Path + "/\(labelID)" + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return LabelAPI.V_DeleteLabelRequest
    }
}


