//
//  FeedbackItem.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/14/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation


enum FeedbackItem: String {
    case header = "Header"
    case rate = "Report Bugs"
    case tweet = "Inbox"
    case facebook = "Starred"
    case contact = "Archive"
    case guide = "Drafts"
    
    var identifier: String { return rawValue }
    
    var image : String {
        switch self {
        case header:
            return ""
        case rate:
            return "feedback_rating"
        case tweet:
            return "feedback_twitter"
        case facebook:
            return "feedback_facebook"
        case contact:
            return "feedback_contact"
        case guide:
            return "feedback_support"
        }
    }
    
    var title : String {
        switch self {
        case header:
            return ""
        case rate:
            return "Rate & Review"
        case tweet:
            return "Tweet about ProtonMail"
        case facebook:
            return "Share it with your friends"
        case contact:
            return "Contact the ProtonMail team"
        case guide:
            return "Trouble shooting guide"
        }
    }
}


enum FeedbackSection: Int {
    case header = 0
    case reviews = 1
    case guid = 2
    case helping = 3 //"Help us to improve ProtonMail with your input"
    
    var identifier: Int { return rawValue }
    
    var hasTitle : Bool {
        var has = false
        switch self {
        case reviews, guid, helping:
            has = true
        default:
            has = false
        }
        return has;
    }
    
    var title : String {
        switch self {
        case header:
            return ""
        case reviews:
            return "Help us to make privacy the default in the web."
        case guid:
            return "Help us to improve ProtonMail with your input."
        case helping:
            return "We would like to know what we can do better."
        }
    }
}

