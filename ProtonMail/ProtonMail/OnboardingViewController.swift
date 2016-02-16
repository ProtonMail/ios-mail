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
    
    
    
    var viewModel : LabelViewModel!
   
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
//        inputContentView.layer.cornerRadius = 4;
//        inputContentView.layer.borderColor = UIColor(hexColorCode: "#DADEE8").CGColor!
//        inputContentView.layer.borderWidth = 1.0
//        self.setupFetchedResultsController()
//        //var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
//        // self.view.addGestureRecognizer(tapGestureRecognizer)
        
        
    }
    

    @IBAction func closeAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
