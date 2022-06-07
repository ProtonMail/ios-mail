//
//  LabelAPI.swift
//  Proton Mail - Created on 8/13/15.
//
//
//  Copyright (c) 2019 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation
import ProtonCore_Networking

// Labels API
// Doc: https://github.com/ProtonMail/Slim-API/blob/develop/api-spec/pm_api_labels.md
struct LabelAPI {
    static let path: String = "/labels"

    static let versionPrefix: String = "/v4"
}

final class GetV4LabelsRequest: Request {
    private let type: Int
    init(type: PMLabelType) {
        self.type = type.rawValue
    }

    var path: String {
        return LabelAPI.versionPrefix + LabelAPI.path + "?Type=\(self.type)"
    }

    var parameters: [String: Any]? {
        return nil
    }
}

/// Parse the response from the server of the GetLabelsRequest() call
final class GetLabelsResponse: Response {
    var labels: [[String: Any]]?
    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.labels = response["Labels"] as? [[String: Any]]
        return true
    }
}

/// Create a label/contact group on the server -- CreateLabelRequestResponse
final class CreateLabelRequest: Request {
    private let name: String
    private let color: String
    private let type: Int
    private let parentID: String?
    private let notify: Int
    private let expanded: Int

    init(name: String, color: String, type: PMLabelType, parentID: String? = nil, notify: Bool, expanded: Bool = true) {
        self.name = name
        self.color = color
        self.type = type.rawValue
        if let id = parentID, !id.isEmpty {
            self.parentID = id
        } else {
            self.parentID = nil
        }
        self.notify = notify ? 1: 0
        self.expanded = expanded ? 1: 0
    }

    var parameters: [String: Any]? {

        var out: [String: Any] = [
            "Name": self.name,
            "Color": self.color,
            "Type": self.type,
            "Notify": self.notify,
            "Expanded": self.expanded
        ]

        if let id = self.parentID {
            out["ParentID"] = id
        }

        return out
    }

    var method: HTTPMethod {
        return .post
    }

    var path: String {
        return LabelAPI.versionPrefix + LabelAPI.path
    }
}

/// Parse the response from the server of the GetLabelsRequest() call
final class CreateLabelRequestResponse: Response {
    var label: [String: Any]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.label = response["Label"] as? [String: Any]
        return true
    }
}

/**
 Update the data of a label/contact group on the server
 
 Type don't need to be specified here since we have the exact labelID to work with
*/
final class UpdateLabelRequest: Request {  // CreateLabelRequestResponse
    private let labelID: String
    private let labelName: String
    private let color: String
    private let parentID: String?
    private let notify: Int

    init(id: String, name: String, color: String, parentID: String? = nil, notify: Bool = false) {
        self.labelID = id
        self.labelName = name
        self.color = color
        if let id = parentID, !id.isEmpty {
            self.parentID = id
        } else {
            self.parentID = nil
        }
        self.notify = notify ? 1: 0
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = [
            "Name": self.labelName,
            "Color": self.color,
            "Notify": self.notify
        ]
        if let id = self.parentID {
            out["ParentID"] = id
        }
        return out
    }

    var method: HTTPMethod {
        return .put
    }

    var path: String {
        return LabelAPI.versionPrefix + LabelAPI.path + "/\(labelID)"
    }
}

/// Parse the response from the server of the UpdateLabelRequest() call
final class UpdateLabelRequestResponse: Response {
    var label: [String: Any]?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.label = response["Label"] as? [String: Any]
        return true
    }
}

/**
 Delete a contact group on the server
 
 Type don't need to be specified here since we have the exact labelID to work with
*/
final class DeleteLabelRequest: Request { // DeleteLabelRequestResponse
    private let labelID: String
    init(lable_id: String) {
        labelID = lable_id
    }

    var method: HTTPMethod {
        return .delete
    }

    var path: String {
        return LabelAPI.versionPrefix + LabelAPI.path + "/\(labelID)"
    }
}

/// Parse the response from the server of the DeleteLabelRequest() call
final class DeleteLabelRequestResponse: Response {
    var returnedCode: Int?

    override func ParseResponse(_ response: [String: Any]!) -> Bool {
        self.returnedCode = response["Code"] as? Int
        return true
    }
}

final class LabelOrderRequest: Request {
    private let siblingLabelID: [String]
    private let parentID: String?
    private let type: PMLabelType

    init(siblingLabelID: [String], parentID: String?, type: PMLabelType) {
        self.siblingLabelID = siblingLabelID
        self.parentID = parentID
        self.type = type
    }

    var parameters: [String: Any]? {
        var out: [String: Any] = ["LabelIDs": self.siblingLabelID,
                                   "Type": self.type.rawValue]
        if let id = self.parentID {
            out["ParentID"] = id
        } else {
            out["ParentID"] = 0
        }
        return out
    }

    var method: HTTPMethod {
        return .put
    }

    var path: String {
        return LabelAPI.versionPrefix + LabelAPI.path + "/order"
    }
}
