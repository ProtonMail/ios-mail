//
//  ContactModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

typealias LockCheckProgress = (() -> Void)
typealias LockCheckComplete = (() -> Void)

@objc protocol ContactPickerModelProtocol {
    
    var contactTitle : String { get }
    
    //@optional
    var displayName : String? { get }
    var displayEmail : String? { get }
    var contactSubtitle : String? { get }
    var contactImage : UIImage? {get}
    var lock: UIImage? {get}
    var notes: String {get}
    
    func lockCheck(progress: LockCheckProgress, complete: LockCheckComplete?)
    
}
