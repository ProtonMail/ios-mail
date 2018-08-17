//
//  PushData.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 12/13/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation

public class PushData {
    
    //in data object
    let title: String
    let subTitle: String?
    let body: String?
    let vibrate: Int?
    let sound: Int?
    let largeIcon: String?
    let smallIcon: String?
    let badge: NSNumber?
    let msgID: String
    let customID: String?
    
    //
    let type: String?
    let version: Int?
    
    
    init(title: String,
         subTitle: String?,
         body: String?,
         vibrate: Int?,
         sound: Int?,
         largeIcon: String?,
         smallIcon: String?,
         badge: NSNumber?,
         msgID: String,
         customID: String?,
         type: String?,
         version: Int?) {
        self.title = title
        self.subTitle = subTitle
        self.body = body
        self.vibrate = vibrate
        self.sound = sound
        self.largeIcon = largeIcon
        self.smallIcon = smallIcon
        self.badge = badge
        self.msgID = msgID
        self.customID = customID
        self.type = type
        self.version = version
    }
    
    //
    func log() -> String {
        return ""
    }
    
    static func parse(with json: String) -> PushData? {
        guard let obj: [String: Any] = json.parseObjectAny() else {
            return nil
        }
        return self.parse(dict: obj)
    }
    
    static func parse(dataString json: String, version: Int?, type: String?) -> PushData? {
        guard let obj: [String: Any] = json.parseObjectAny() else {
            return nil
        }
        return self.parse(dataDict: obj, version: version, type: type)
    }
    
    static func parse(dataDict data: [String: Any], version: Int?, type: String?) -> PushData? {

        guard let title = data["title"] as? String else {
            return nil
        }
        
        guard let msgID = data["messageId"] as? String else {
            return nil
        }
        
        let subtitle = data["subtitle"] as? String
        let body = data["body"] as? String
        let vibrate = data["vibrate"] as? Int
        let sound = data["sound"] as? Int
        let lIcon = data["largeIcon"] as? String
        let sIcon = data["smallIcon"] as? String
        let badge = data["badge"] as? NSNumber
        let cusID = data["customId"] as? String
        
        return PushData(title: title,
                        subTitle: subtitle,
                        body: body,
                        vibrate: vibrate,
                        sound: sound,
                        largeIcon: lIcon,
                        smallIcon: sIcon,
                        badge: badge,
                        msgID: msgID,
                        customID: cusID,
                        type: type,
                        version: version)
    }
    
    static func parse(dict obj: [String: Any]) -> PushData? {
        
        let v = obj["version"] as? Int
        let type = obj["type"] as? String
        
        guard let data = obj["data"] as? [String: Any] else {
            return nil
        }
        
        guard let title = data["title"] as? String else {
            return nil
        }
        
        guard let msgID = data["messageId"] as? String else {
            return nil
        }

        let subtitle = data["subtitle"] as? String
        let body = data["body"] as? String
        let vibrate = data["vibrate"] as? Int
        let sound = data["sound"] as? Int
        let lIcon = data["largeIcon"] as? String
        let sIcon = data["smallIcon"] as? String
        let badge = data["badge"] as? NSNumber
        let cusID = data["customId"] as? String
        
        return PushData(title: title,
                        subTitle: subtitle,
                        body: body,
                        vibrate: vibrate,
                        sound: sound,
                        largeIcon: lIcon,
                        smallIcon: sIcon,
                        badge: badge,
                        msgID: msgID,
                        customID: cusID,
                        type: type,
                        version: v)
    }
}
