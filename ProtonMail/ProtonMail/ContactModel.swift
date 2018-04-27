//
//  ContactModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 4/26/18.
//  Copyright © 2018 ProtonMail. All rights reserved.
//

import UIKit


protocol ContactPickerModelProtocol {
    
//    @required
//
//    @property (readonly, nonatomic, copy) NSString *contactTitle;
//
//    @optional
//
//    @property (readonly, nonatomic, copy) NSString *contactSubtitle;
//    @property (readonly, nonatomic) UIImage *contactImage;
//
//    @end
}



struct ContactModel : ContactPickerModelProtocol {

    var contactTitle : String
    
    var contactSubtitle : String
    
    var contactImage : UIImage
}
