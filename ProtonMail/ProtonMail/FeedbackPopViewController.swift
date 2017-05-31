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
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    
    @IBAction func ilikeitAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        feedbackDelegate?.showRating()
    }
    
    @IBAction func itisokAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        feedbackDelegate?.showHelp()
    }
    @IBAction func dontlikeAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        feedbackDelegate?.showSupport()
        
    }
    @IBAction func cancelAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
        feedbackDelegate?.cancelled()
    }
    
} 
