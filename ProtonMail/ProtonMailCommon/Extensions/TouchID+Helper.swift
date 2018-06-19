//
//  TouchID+Helper.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import Foundation
import LocalAuthentication


enum BiometricType {
    case none
    case touchID
    case faceID
}

var biometricType: BiometricType {
    get {
        let context = LAContext()
        var error: NSError?
        
        if #available(iOS 9.0, *) {
            guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
                print(error?.localizedDescription ?? "")
                return .none
            }
            if #available(iOS 11.0, *) {
                switch context.biometryType {
                case .none:
                    return .none
                case .touchID:
                    return .touchID
                case .faceID:
                    return .faceID
                }
            } else {
                return  .touchID
            }
        } else {
            return .touchID
        }
        

    }
}
