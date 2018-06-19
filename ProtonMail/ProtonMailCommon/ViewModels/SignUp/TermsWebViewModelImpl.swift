//
//  WebViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class TermsWebViewModelImpl : WebViewModel {
 
    override var url: URL {
        get {
            return URL(string: "https://protonmail.com/ios-terms-and-conditions.html")!
        }
    }
    
}
