//
//  PMDocumentPickerViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/31/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation


class PMDocumentPickerViewController : UIDocumentPickerViewController {
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.All
    }
    
    override func shouldAutorotate() -> Bool {
        return true
    }
}