//
//  ContactModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit

typealias LockCheckProgress = (() -> Void)
typealias LockCheckComplete = ((_ lock: UIImage?, _ lockType : Int) -> Void)

@objc enum ContactPickerModelState: Int
{
    case contact = 1
    case contactGroup = 2
}

@objc protocol ContactPickerModelProtocol: class {
    
    var modelType: ContactPickerModelState { get }
    var contactTitle : String { get }
    
    //@optional
    var displayName : String? { get }
    var displayEmail : String? { get }
    var contactSubtitle : String? { get }
    var contactImage : UIImage? {get}
    var lock: UIImage? {get}
    var hasPGPPined : Bool {get}
    var hasNonePM : Bool {get}
    func notes(type: Int) -> String
    func setType(type: Int)
    func lockCheck(progress: LockCheckProgress, complete: LockCheckComplete?)
}
