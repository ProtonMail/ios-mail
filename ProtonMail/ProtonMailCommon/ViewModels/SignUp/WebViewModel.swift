//
//  WebViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/12/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation


class WebViewModel : NSObject {
    
    func getUrl() -> URL {
        fatalError("This method must be overridden")
    }
    
    var url : URL {
        get {
            fatalError("This method must be overridden")
        }
    }
}
