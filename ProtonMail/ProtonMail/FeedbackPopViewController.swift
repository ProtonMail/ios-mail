//
//  FeedbackViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/11/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//
protocol FeedbackPopViewControllerDelegate {
    func cancelled();
    
    func showRating();
    
    func showHelp();
    
    func showSupport();
}

class FeedbackPopViewController : UIViewController {
    
    var feedbackDelegate : FeedbackPopViewControllerDelegate?;
   
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    @IBAction func ilikeitAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        feedbackDelegate?.showRating()
    }
    
    @IBAction func itisokAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        feedbackDelegate?.showHelp()
    }
    @IBAction func dontlikeAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        feedbackDelegate?.showSupport()
        
    }
    @IBAction func cancelAction(sender: UIButton) {
        self.dismissViewControllerAnimated(true, completion: nil)
        feedbackDelegate?.cancelled()
    }
    
} 