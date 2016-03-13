//
//  FeedbackViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//
protocol FeedbackPopViewControllerDelegate {
    func dismissed();
}

class FeedbackPopViewController : UIViewController {
    
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func ilikeitAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func itisokAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    
    }
    @IBAction func dontlikeAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        
    }
    @IBAction func cancelAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
} 