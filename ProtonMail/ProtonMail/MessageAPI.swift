//
//  MessageAPI.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/18/15.
//  Copyright (c) 2015 Proton Reserch. All rights reserved.
//

import Foundation
import PromiseKit
import AwaitKit

// MARK : Get messages part
final class MessageCount : ApiRequest<MessageCountResponse> {
    override open func path() -> String {
        return MessageAPI.path + "/count" + AppConstants.DEBUG_OPTION
    }
    override func apiVersion() -> Int {
        return MessageAPI.v_message_count
    }
}

final class MessageCountResponse : ApiResponse {
    var counts : [[String : Any]]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.counts = response?["Counts"] as? [[String : Any]]
        return true
    }
}


// MARK : Get messages part
final class FetchMessages : ApiRequest<ApiResponse> {
    let location : MessageLocation!
    let startTime : Int?
    let endTime : Int
    
    init(location:MessageLocation, endTime : Int = 0) {
        self.location = location
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        if self.location == MessageLocation.starred {
            out["Starred"] = 1
        } else {
            out["Location"] = self.location.rawValue
        }
        if(self.endTime > 0)
        {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        
        PMLog.D( out.json(prettyPrinted: true) )
        
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}

final class FetchMessagesByID : ApiRequest<ApiResponse> {
    let messages : [Message]!
    init(messages: [Message]) {
        self.messages = messages
    }
    
    internal func buildURL () -> String {
        var out = "";
        
        for message in self.messages {
            if message.managedObjectContext != nil {
                if !out.isEmpty {
                    out = out + "&"
                }
                out = out + "ID[]=\(message.messageID)"
            }
        }
        if !out.isEmpty {
            out = "?" + out
        }
        return out;
    }
    
    override func path() -> String {
        return MessageAPI.path + self.buildURL()
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}


final class FetchMessagesByLabel : ApiRequest<ApiResponse> {
    let labelID : String!
    let startTime : Int?
    let endTime : Int
    
    init(labelID : String, endTime : Int = 0) {
        self.labelID = labelID
        self.endTime = endTime
        self.startTime = 0
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = ["Sort" : "Time"]
        out["Label"] = self.labelID
        if self.endTime > 0 {
            let newTime = self.endTime - 1
            out["End"] = newTime
        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_fetch_messages
    }
}

// MARK : Create/Update Draft Part

/// create draft message request class
class CreateDraft : ApiRequest<MessageResponse> {
    
    let message : Message!;
    
    init(message: Message!) {
        self.message = message
    }
    
    override func toDictionary() -> [String : Any]? {
        let address_id : String                 = message.getAddressID
        var messsageDict : [String : Any] = [
            "AddressID" : address_id,
            "Body" : message.body,
            "Subject" : message.title,
            "IsRead" : message.isRead]
        
        messsageDict["ToList"]  = message.recipientList.parseJson()
        messsageDict["CCList"]  = message.ccList.parseJson()
        messsageDict["BCCList"] = message.bccList.parseJson()
        var out : [String : Any] = ["Message" : messsageDict]
        
        if let orginalMsgID = message.orginalMessageID {
            if !orginalMsgID.isEmpty {
                out["ParentID"] = message.orginalMessageID
                out["Action"] = message.action ?? "0"  //{0|1|2} // Optional, reply = 0, reply all = 1, forward = 2 m
            }
        }
        
        if let attachments = self.message?.attachments.allObjects as? [Attachment] {
            var atts : [String : String] = [:]
            for att in attachments {
                if att.keyChanged {
                    atts[att.attachmentID] = att.keyPacket
                }
            }
            out["AttachmentKeyPackets"] = atts
        }
        
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_create_draft
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
}

/// message update draft api request
final class UpdateDraft : CreateDraft {

    override func path() -> String {
        return MessageAPI.path + "/" + message.messageID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_update_draft
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
}


final class MessageResponse : ApiResponse {
    var message : [String : Any]?
    override func ParseResponse(_ response: [String : Any]!) -> Bool {
        self.message = response?["Message"] as? [String : Any]
        return true
    }
}


// MARK : Message actions part

/// mesaage action request PUT method
final class MessageActionRequest : ApiRequest<ApiResponse> {
    let messages : [Message]!
    let action : String!
    var ids : [String] = [String] ()

    public init(action:String, messages: [Message]!) {
        self.messages = messages
        self.action = action
        for message in messages {
            if message.isDetailDownloaded {
                ids.append(message.messageID)
            }
        }
    }
    
    public init(action:String, ids : [String]!) {
        self.action = action
        self.ids = ids
        self.messages = [Message]()
    }
    
    override func toDictionary() -> [String : Any]? {
        let out = ["IDs" : self.ids]
        // PMLog.D(self.JSONStringify(out, prettyPrinted: true))
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + "/" + self.action + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.V_MessageActionRequest
    }
    
    override func method() -> APIService.HTTPMethod {
        return .put
    }
}

/// empty trash or spam
final class MessageEmptyRequest : ApiRequest <ApiResponse> {
    let location : String!
    
    public init(location: String! ) {
        self.location = location
    }
    
    override func toDictionary() -> [String : Any]? {
        return nil
    }
    
    override func path() -> String {
        return MessageAPI.path + "/" + location + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_empty_label_folder
    }
    
    override func method() -> APIService.HTTPMethod {
        return .delete
    }
}

// MARK : Message Send part

struct SendType : OptionSet {
    let rawValue: Int
    
    //address package one
    
    //internal email
    static let intl    = SendType(rawValue: 1 << 0)
    //encrypt outside
    static let eo      = SendType(rawValue: 1 << 1)
    //cleartext inline
    static let cinln   = SendType(rawValue: 1 << 2)
    //inline pgp
    static let inlnpgp = SendType(rawValue: 1 << 3)
    
    //address package two MIME
    
    //pgp mime
    static let pgpmime = SendType(rawValue: 1 << 4)
    //clear text mime
    static let cmime   = SendType(rawValue: 1 << 5)
    
}




class PreAddress {
    let email : String!
    let recipintType : Int!
    let eo : Bool
    let pubKey : String?
    init(email : String, pubKey : String?, recipintType : Int, eo : Bool ) {
        self.email = email
        self.recipintType = recipintType
        self.eo = eo
        self.pubKey = pubKey
    }
}

class SendBuilder {
    var bodyDataPacket : Data!
    var bodySession : Data!
    var preAddresses : [PreAddress] = [PreAddress]()

    init() { }
    
    func update(bodyData : Data, bodySession : Data) {
        self.bodyDataPacket = bodyData
        self.bodySession = bodySession
    }
    
    func add(address: PreAddress) {
        preAddresses.append(address)
    }
    
    private func build(type rt : Int, eo : Bool) -> SendType {
        switch (rt, eo) {
        case (1, _):
            return SendType.intl
        case (2, true):
            return SendType.eo
        case (_, _):
            //should not be here
            break
        }
        return SendType.intl
    }
    
    
    var builders : [PackageBuilder] {
        get {
            var out : [PackageBuilder] = [PackageBuilder]()
            for pre in preAddresses {
                switch self.build(type: pre.recipintType, eo: pre.eo) {
                case .intl:
                    out.append(AddressBuilder(type: .intl, addr: pre, session: self.bodySession))
                    break;
                    
                default:
                    break
                }
                
            }
            return out
        }
    }
    
    var promises : [Promise<AddressPackageBase>] {
        get {
            var out : [Promise<AddressPackageBase>] = [Promise<AddressPackageBase>]()
            for it in builders {
                out.append(it.build())
            }
            return out
        }
    }
    
    var encodedBody : String {
        get {
            return self.bodyDataPacket.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        }
    }
    
    var outSideUser : Bool {
        get {
            for pre in preAddresses {
                if pre.recipintType == 2 {
                    return true
                }
            }
            return false
        }
    }
}

protocol IPackageBuilder {
    func build() -> Promise<AddressPackageBase>
}

class PackageBuilder : IPackageBuilder {
    let preAddress : PreAddress
    func build() -> Promise<AddressPackageBase> {
        fatalError("This method must be overridden")
    }
    
    let sendType : SendType!
    
    init(type : SendType, addr : PreAddress) {
        self.sendType = type
        self.preAddress = addr
    }
    
}

class EOAddressBuilder : PackageBuilder {
    override func build() -> Promise<AddressPackageBase> {
        return async {
            let auth = PasswordAuth(modulus_id: "", salt: "", verifer: "")
            let eo = EOAddressPackage(token: "", encToken: "", auth: auth, pwdHit: nil, email: "", bodyKeyPacket: "")
            return eo
        }
    }
}

class AddressBuilder : PackageBuilder {
    let session : Data
    init(type: SendType, addr: PreAddress, session: Data) {
        self.session = session
        super.init(type: type, addr: addr)
    }
    
    override func build() -> Promise<AddressPackageBase> {
        
        return async {
            
            
            
            // encrypt keys use key
            //                            var attPack : [AttachmentKeyPackage] = []
            //                            for att in tempAtts {
            //                                //attID:String!, attKey:String!, Algo : String! = ""
            //                                let newKeyPack = try att.Key?.getPublicSessionKeyPackage(publicKey)?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            //                                let attPacket = AttachmentKeyPackage(attID: att.ID, attKey: newKeyPack)
            //                                attPack.append(attPacket)
            //                            }
            //                            //create inside packet
            //                            if let encryptedBody = try body.encryptMessageWithSingleKey(publicKey, privateKey: privKey, mailbox_pwd: pwd) {
            //                                let pack = MessagePackage(address: key, type: 1, body: encryptedBody, attPackets: attPack)
            //                                out.append(pack)
            //                            }
            
            let newKeypacket = try self.session.getPublicSessionKeyPackage(self.preAddress.pubKey!)
            let newEncodedKey = newKeypacket?.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0)) ?? ""
            //throw  error later
            let addr = AddressPackage(email: self.preAddress.email, bodyKeyPacket: newEncodedKey)

            
            return addr
        }
    }
}

class ClearBuilder : PackageBuilder {
    override func build() -> Promise<AddressPackageBase> {
        return async {
//            let auth = PasswordAuth(modulus_id: "", salt: "", verifer: "")
            let eo = AddressPackage(email: "", bodyKeyPacket: "")
            return eo
        }
    }
}



/// message packages
final class EOAddressPackage : AddressPackage {

    let token : String!  //<random_token>
    let encToken : String! //<encrypted_random_token>
    let auth : PasswordAuth! //
    let pwdHit : String?  //"PasswordHint" : "Example hint", // optional

    init(token: String, encToken : String,
         auth : PasswordAuth, pwdHit : String?,
         email:String,
         bodyKeyPacket : String,
         attPackets:[AttachmentKeyPackage]=[AttachmentKeyPackage](),
         type: SendType = SendType.intl, //for base
         sign : Int = 0) {
        
        self.token = token
        self.encToken = encToken
        self.auth = auth
        self.pwdHit = pwdHit
        
        super.init(email: email, bodyKeyPacket: bodyKeyPacket, attPackets: attPackets, type: type, sign: sign)
    }
    
    override func toDictionary() -> [String : Any]? {
        var out = super.toDictionary() ?? [String : Any]()
        out["Token"] = self.token
        out["EncToken"] = self.encToken
        out["Auth"] = self.auth.toDictionary()
        if let hit = self.pwdHit {
            out["PasswordHint"] = hit
        }
        return out
    }
}

class AddressPackage : AddressPackageBase {
    let bodyKeyPacket : String
    let attPackets : [AttachmentKeyPackage]

    init(email:String,
         bodyKeyPacket : String,
         attPackets:[AttachmentKeyPackage]=[AttachmentKeyPackage](),
         type: SendType = SendType.intl, //for base
         sign : Int = 0) {
        self.bodyKeyPacket = bodyKeyPacket
        self.attPackets = attPackets
        super.init(email: email, type: type, sign: sign)
    }

    override func toDictionary() -> [String : Any]? {
        var out = super.toDictionary() ?? [String : Any]()
        out["BodyKeyPacket"] = self.bodyKeyPacket
        
        //change to == id : packet
        if attPackets.count > 0 {
            var atts : [Any] = [Any]()
            for attPacket in attPackets {
                atts.append(attPacket.toDictionary()!)
            }
            out["AttachmentKeyPackets"] = atts
            
        }

        return out
    }
}

class AddressPackageBase : Package {
    
    let type : SendType!
    let sign : Int! //0 or 1
    let email : String
    
    init(email: String, type: SendType, sign : Int) {
        self.type = type
        self.sign = sign
        self.email = email
    }
    
    func toDictionary() -> [String : Any]? {
        return [
            "Type" : type.rawValue,
            "Signature" : sign
        ]
    }
}



/// send message reuqest
final class SendMessage : ApiRequestNew<ApiResponse> {
    var messagePackage : [AddressPackageBase]!     // message package
    var attPackets : [AttachmentKeyPackage]!    //  for optside encrypt att.
    var body : String!                     //  optional for out side user
    let messageID : String!
    let expirationTime : Int32!
    
    init(messageID : String, expirationTime: Int32?, messagePackage: [AddressPackageBase]!, body : String, attPackages:[AttachmentKeyPackage] = [AttachmentKeyPackage]()) {
        self.messageID = messageID
        self.messagePackage = messagePackage
        self.body = body
        self.attPackets = attPackages
        self.expirationTime = expirationTime ?? 0
    }
    
    override func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [String : Any]()
        out["ExpirationTime"] = self.expirationTime
        //optional this will override app setting
        //out["AutoSaveContacts"] = "\(0 / 1)"

        
        //packages object
        var packages : [Any] = [Any]()
        
        //not mime
        var normalAddress : [String : Any] = [String : Any]()
        var addrs = [String: Any]()
        var type = SendType()
        for mp in messagePackage {
            addrs[mp.email] = mp.toDictionary()!
            type.insert(mp.type)
        }
        normalAddress["Addresses"] = addrs
        normalAddress["Type"] = type.rawValue //"Type": 15, // 8|4|2|1, all types sharing this package, a bitmask
        
        
        normalAddress["Body"] = self.body
        normalAddress["MIMEType"] = "text/html"
        
        //
        if type.contains(.cinln) {
            normalAddress["BodyKey"] = "[:]" // Include only if cleartext recipients
//            "BodyKey": {
//                "Key": <base64_encoded_session_key>,
//                "Algorithm": "aes256" // algorithm corresponding to session key
//            },
        }
        
        if attPackets.count > 0 {
            normalAddress["AttachmentKeys"] = "[:]" // Only include if cleartext recipients, optional if no attachments
        //        "AttachmentKeys": {
        //            "<attachment_id>" : {
        //                "Key": <base64_encoded_session_key>,
        //                "Algorithm": "aes256" // algorithm corresponding to session key
        //            }
        //        },
        }
        packages.append(normalAddress)
        
        //mime
        var mimeAddress : [String : Any] = [String : Any]()
        mimeAddress["Addresses"] = "[:]()"
//        "bartqa2@pgp.me" : {
//        "Type" : 16, // PGP/MIME
//        "BodyKeyPacket" : <base64_encoded_key_packet>
//        },
//        "bartqa3@gmail.com" : {
//        "Type" : 32, // cleartext MIME
//        "Signature" : 0 // 1 = signature
//        }
        mimeAddress["Type"] = "get from message list" // 16|32 MIME sending cannot share packages with inline sending
        mimeAddress["Body"] = "<base64_encoded_openpgp_encrypted_data_packet>"
        mimeAddress["MIMEType"] = "multipart/mixed"
        mimeAddress["BodyKey"] = "[:]" // Include only if cleartext MIME recipients
        //        "BodyKey": {
        //            "Key": <base64_encoded_session_key>,
        //            "Algorithm": "aes256" // algorithm corresponding to session key
        //        },
//        packages.append(mimeAddress)
        out["Packages"] = packages
        
//        if !self.clearBody.isEmpty {
//            out["ClearBody"] = self.clearBody
//        }
//
//        if self.attPackets != nil {
//            var attPack : [Any] = [Any]()
//            for pack in self.attPackets {
//                //TODO:: ! check
//                attPack.append(pack.toDictionary()!)
//            }
//            out["AttachmentKeys"] = attPack
//        }
//
//
//        var package : [Any] = [Any]()
//        if self.messagePackage != nil {
//            for pack in self.messagePackage {
//                //TODO:: ! check
//                package.append(pack.toDictionary()!)
//            }
        //        }
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + "/" + self.messageID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return MessageAPI.v_send_message
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
}



/// send message reuqest
final class MessageSendRequest<T: ApiResponse>  : ApiRequest<T> {
    var messagePackage : [MessagePackage]!     // message package
    var attPackets : [AttachmentKeyPackage]!    //  for optside encrypt att.
    var clearBody : String!                     //  optional for out side user
    let messageID : String!
    let expirationTime : Int32?
    
    init(messageID : String!, expirationTime: Int32?, messagePackage: [MessagePackage]!, clearBody : String! = "", attPackages:[AttachmentKeyPackage]! = nil) {
        self.messageID = messageID
        self.messagePackage = messagePackage
        self.clearBody = clearBody
        self.attPackets = attPackages
        self.expirationTime = expirationTime
    }
    
    override func toDictionary() -> [String : Any]? {

        
        var out : [String : Any] = [String : Any]()
        
        if !self.clearBody.isEmpty {
            out["ClearBody"] = self.clearBody
        }
        
        if self.attPackets != nil {
            var attPack : [Any] = [Any]()
            for pack in self.attPackets {
                //TODO:: ! check
                attPack.append(pack.toDictionary()!)
            }
            out["AttachmentKeys"] = attPack
        }
        
        if let expTime = expirationTime {
            if expTime > 0 {
                out["ExpirationTime"] = "\(expTime)"
            }
        }
        
        var package : [Any] = [Any]()
        if self.messagePackage != nil {
            for pack in self.messagePackage {
                //TODO:: ! check
                package.append(pack.toDictionary()!)
            }
        }
        out["Packages"] = package
        PMLog.D( out.json(prettyPrinted: true) )
        return out
    }
    
    override func path() -> String {
        return MessageAPI.path + "/send/" + self.messageID + AppConstants.DEBUG_OPTION
    }
    
    override func apiVersion() -> Int {
        return 1
    }
    
    override func method() -> APIService.HTTPMethod {
        return .post
    }
}

/// message packages
final class MessagePackage : Package {
    
    /// default sender email address
    let address : String!
    /** send encrypt message package type
    *   1 internal
    *   2 external
    */
    let type : Int!
    /// encrypt message body
    let body : String!
    /// optional for outside
    let token : String!
    /// optional for outside
    let encToken : String!
    /// optional encrypt password hint
    let passwordHint : String!
    /// optional attachment package
    let attPackets : [AttachmentKeyPackage]
    
    /**
    message packages
    
    :param: address    addresses
    :param: type       package type
    :param: body       package encrypt body
    :param: token      eo token optional only for encrypt outside
    :param: encToken   eo encToken optional only for encrypt outside
    :param: attPackets attachment package
    
    :returns: self
    */
    init(address:String, type : Int, body :String!, attPackets:[AttachmentKeyPackage]=[AttachmentKeyPackage](), token : String! = "", encToken : String! = "", passwordHint : String! = "") {
        self.address = address
        self.type = type
        self.body = body
        self.token = token
        self.encToken = encToken
        self.passwordHint = passwordHint
        self.attPackets = attPackets
    }
    
    // Mark : override class functions
    func toDictionary() -> [String : Any]? {
        var atts : [Any] = [Any]()
        for attPacket in attPackets {
            atts.append(attPacket.toDictionary()!)
        }
        var out : [String : Any] = [
            "Address" : self.address,
            "Type" : self.type,
            "Body" : self.body,
            "KeyPackets" : atts]
        
        if !self.token!.isEmpty {
            out["Token"] = self.token
        }
        
        if !self.encToken.isEmpty {
            out["EncToken"] = self.encToken
        }
        
        if !self.passwordHint.isEmpty {
            out["PasswordHint"] = self.passwordHint
        }
        return out
    }
}


// message attachment key package
final class AttachmentKeyPackage : Package {
    let ID : String!
    let keyPacket : String!
    let algo : String!
    init(attID:String!, attKey:String!, Algo : String! = "") {
        self.ID = attID
        self.keyPacket = attKey
        self.algo = Algo
    }
    
    func toDictionary() -> [String : Any]? {
        var out : [String : Any] = [ "ID" : self.ID ]
        if !self.algo.isEmpty {
            out["Algo"] = self.algo
            out["Key"] = self.keyPacket
        } else {
            out["KeyPackets"] = self.keyPacket
        }
        return out
    }
}


/**
*  temporary table for formating the message send package
*/
final class TempAttachment {
    let ID : String!
    let Key : Data?
    
    public init(id: String, key: Data?) {
        self.ID = id
        self.Key = key
    }
}



/**
* MARK : down all the old code
*/

/**
*  contact
*/
public struct Contacts {
    let email: String
    let name: String
    
    init(email: String, name: String) {
        self.name = name
        self.email = email
    }
    
    func asJSON() -> [String : Any] {
        return [
            "Name" : self.name,
            "Email" : self.email]
    }
}

//    public struct Attachment {
//        let fileName: String
//        let mimeType: String
//        let fileData: [String:String]
//        let fileSize: Int
//
//        init(fileName: String, mimeType: String, fileData: [String:String], fileSize: Int) {
//            self.fileName                           = fileName
//            self.mimeType                           = mimeType
//            self.fileData                           = fileData
//            self.fileSize                           = fileSize
//        }
//
//        func asJSON() -> [String:Any] {
//            return [
//                "FileName" : fileName,
//                "MIMEType" : mimeType,
//                "FileData" : fileData,
//                "FileSize" : String(fileSize)]
//        }
//    }





