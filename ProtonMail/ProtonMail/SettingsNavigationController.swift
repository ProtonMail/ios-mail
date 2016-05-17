//
//  SettingsNavigationController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 5/2/16.
//  Copyright (c) 2016 ProtonMail. All rights reserved.
//

import Foundation

//class SettingsNavigationController : UINavigationController {
//    
//    
//    override func viewWillAppear(animated: Bool) {
//        super.viewWillAppear(animated)
//    }
//    
//    public override func shouldAutorotate() -> Bool {
//        return visibleViewController.shouldAutorotate()
//    }
//    
//    public override func supportedInterfaceOrientations() -> Int {
//        if visibleViewController is PinCodeViewController {
//            return Int(UIInterfaceOrientationMask.Landscape.rawValue)
//        }
//        return Int(UIInterfaceOrientationMask.All.rawValue)
//    }
//}
////
////extension SWRevealViewController {
////    public override func supportedInterfaceOrientations() -> Int {
////        return Int(UIInterfaceOrientationMask.Portrait.rawValue)
////    }
//////    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//////        return UI //(visibleViewController?.supportedInterfaceOrientations())!
//////    }
////}
////
////
//extension UINavigationController {
//    public override func shouldAutorotate() -> Bool {
//        return visibleViewController.shouldAutorotate()
//    }
//    
//    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
//        return (visibleViewController?.supportedInterfaceOrientations())!
//    }
//}