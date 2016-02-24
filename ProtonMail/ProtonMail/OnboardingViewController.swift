//
//  OnboardingViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/16/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation



class OnboardingViewController : UIViewController {
    
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    
    var viewModel : LabelViewModel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
    
        let p = self.view.frame;
        
        var boardView = OnboardingView(frame: CGRect(x: 0,y: 0,width: p.width - 40, height: p.height - 84))
        
        self.contentScrollView.addSubview(boardView);
        
    }
    
    override func viewWillAppear(animated: Bool) {
        let f = contentView.frame;
        
        
    }
    

    @IBAction func closeAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
