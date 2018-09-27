//
//  URL+Extension.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


extension URL {
    // protonmail app store link
    static var appleStore: URL {
        return URL(string: "itms-apps://itunes.apple.com/app/id979659905")!
    }
    
    // kb for force upgrade
    static var kbUpdateRequired : URL {
        return URL(string: "https://protonmail.com/support/knowledge-base/update-required")!
    }
    
    // leanr more about encrypt outside - composer view
    static var kEOLearnMore : URL {
        return URL(string: "https://protonmail.com/support/knowledge-base/encrypt-for-outside-users/")!
    }
}
