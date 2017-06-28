//
//  ShareExtensionEntry.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 6/28/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation
import UIKit

@objc(ShareExtensionEntry)

class ShareExtensionEntry : UINavigationController {
    
    init() {
//        let storyboard = UIStoryboard(name: "SignIn", bundle: nil)
//        let vc = storyboard.instantiateViewController(withIdentifier: "ShareViewController")
//        //        self.presentViewController(vc, animated: true, completion: nil)
//        //        let sb = UIStoryboard.get
//        //        UIStoryboard *sb = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//        //        UIViewController *vc = [sb instantiateViewControllerWithIdentifier:@"myViewController"];
//        //        vc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
//        //        [self presentViewController:vc animated:YES completion:NULL];
//        //let vc = ShareComposeViewController(nibName: "ShareComposeViewController", bundle: nil)
//        
//        super.init(rootViewController: vc)

        
        super.init(rootViewController: ShareViewController())
        
//        self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: "cancelButtonTapped:")
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.save, target: self, action: "saveButtonTapped:")
       
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.view.transform = CGAffineTransform(translationX: 0, y: self.view.frame.size.height)
        UIView.animate(withDuration: 0.50, animations: { () -> Void in
            self.view.transform = CGAffineTransform.identity
        })
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}
