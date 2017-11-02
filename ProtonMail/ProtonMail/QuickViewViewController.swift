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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent;
    }
    
    func configureNavigationBar(_ navigationController: UINavigationController) {
        navigationController.navigationBar.barStyle = UIBarStyle.black
        navigationController.navigationBar.barTintColor = UIColor.ProtonMail.Nav_Bar_Background;
        navigationController.navigationBar.isTranslucent = false
        navigationController.navigationBar.tintColor = UIColor.white
        
        let navigationBarTitleFont = UIFont.robotoLight(size: UIFont.Size.h2)
        navigationController.navigationBar.titleTextAttributes = [
            NSAttributedStringKey.foregroundColor: UIColor.white,
            NSAttributedStringKey.font: navigationBarTitleFont
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let views = self.childViewControllers
        if views.count > 0 {
            if let nav = views[0] as? UINavigationController {
                configureNavigationBar(nav)
                setNeedsStatusBarAppearanceUpdate()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        isPresented = false
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate : Bool {
        
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}
