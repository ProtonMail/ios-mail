//
//  ContactModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


@objc protocol ContactPickerModelProtocol {
    
    var contactTitle : String { get }
    
    //@optional
    var contactSubtitle : String? { get }
    var contactImage : UIImage? {get}
}
