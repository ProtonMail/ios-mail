//
//  FeedbackItem.swift
//  ProtonMail - Created on 3/14/16.
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
        case .header:
            return ""
        case .rate:
            return "feedback_rating"
        case .tweet:
            return "feedback_twitter"
        case .facebook:
            return "feedback_facebook"
        case .contact:
            return "feedback_contact"
        case .guide:
            return "feedback_support"
        }
    }
    
    var title : String {
        switch self {
        case .header:
            return ""
        case .rate:
            return LocalString._rate_review
        case .tweet:
            return LocalString._tweet_about_protonmail
        case .facebook:
            return LocalString._share_it_with_your_friends
        case .contact:
            return LocalString._contact_the_protonmail_team
        case .guide:
            return LocalString._trouble_shooting_guide
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
        case .reviews, .guid, .helping:
            has = true
        default:
            has = false
        }
        return has;
    }
    
    var title : String {
        switch self {
        case .header:
            return ""
        case .reviews:
            return LocalString._help_us_to_make_privacy_the_default_in_the_web
        case .guid:
            return LocalString._help_us_to_improve_protonmail_with_your_input
        case .helping:
            return LocalString._we_would_like_to_know_what_we_can_do_better
        }
    }
}

