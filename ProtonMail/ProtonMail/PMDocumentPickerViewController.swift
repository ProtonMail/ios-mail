//
//  PMDocumentPickerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/31/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class PMDocumentPickerViewController : UIDocumentPickerViewController {
    
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.all
    }
    
    override var shouldAutorotate : Bool {
        return true
    }
}
