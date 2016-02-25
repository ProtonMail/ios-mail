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
    
    let onboardingList : [Onboarding] = [.welcome, .swipe, .label, .encryption, .expire, .help]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
    
        let p = self.view.frame;
        
        let h : CGFloat = p.height - 84
        let w : CGFloat = p.width - 40
        
        let count = onboardingList.count
        for i in 0 ..< count {
            let board = onboardingList[i]
            let xPoint : CGFloat =  w * CGFloat(i)
            var boardView = OnboardingView(frame: CGRect(x:xPoint, y: 0, width: w, height: h))
            boardView.configView(board)
            self.contentScrollView.addSubview(boardView);
        }
        contentScrollView.contentSize = CGSize (width: w * CGFloat(count), height: contentScrollView.contentSize.height);
    }

    @IBAction func closeAction(sender: AnyObject) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
 
    
    
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
}
