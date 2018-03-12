//
//  WebViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class PolicyWebViewModelImpl : WebViewModel {
 
    override var url: URL {
        get {
            return URL(string: "https://protonmail.com/ios-privacy-policy.html")!
        }
    }
    
}
