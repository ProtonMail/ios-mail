//
//  QuickViewViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/21/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit
import QuickLook


class QuickViewViewController: QLPreviewController {

    var isPresented = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }
    
    func configureNavigationBar(navigationController: UINavigationController) {
        navigationController.navigationBar.barStyle = UIBarStyle.Black
        navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        navigationController.navigationBar.translucent = false
        navigationController.navigationBar.tintColor = UIColor.whiteColor()
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        navigationController.navigationBar.titleTextAttributes = [
            NSForegroundColorAttributeName: UIColor.whiteColor(),
            NSFontAttributeName: navigationBarTitleFont
        ]
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let views = self.childViewControllers
        if views.count > 0 {
            if let nav = views[0] as? UINavigationController {
                configureNavigationBar(nav)
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        isPresented = false
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func shouldAutorotate() -> Bool {
        
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
