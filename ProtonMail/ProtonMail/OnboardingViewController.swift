//
//  OnboardingViewController.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 2/16/16.
//  Copyright (c) 2016 ArcTouch. All rights reserved.
//

import Foundation

class OnboardingViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var pageControlView: UIPageControl!
    @IBOutlet weak var learnmoreButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
     fileprivate let upgradePageUrl = URL(string: "https://protonmail.com/upgrade")!
    
    var pageWidth : CGFloat = 0.0;
    
    let onboardingList : [Onboarding] = [.welcome, .swipe, .label, .encryption, .expire, .help] //, .upgrade]
   
    override func viewDidLoad() {
        super.viewDidLoad()
        contentView.layer.cornerRadius = 4;
        learnmoreButton.isHidden = true
        let p = self.view.frame;
        
        let h : CGFloat = p.height - 84
        pageWidth = p.width - 40
        
        let count = onboardingList.count
        for i in 0 ..< count {
            let board = onboardingList[i]
            let xPoint : CGFloat =  pageWidth * CGFloat(i)
            let boardView = OnboardingView(frame: CGRect(x:xPoint, y: 0, width: pageWidth, height: h))
            boardView.configView(board)
            self.contentScrollView.addSubview(boardView);
        }
        contentScrollView.contentSize = CGSize (width: pageWidth * CGFloat(count), height: contentScrollView.contentSize.height);
        pageControlView.numberOfPages = count;
        pageControlView.currentPage = 0;
        
        closeButton.setTitle(NSLocalizedString("close tour", comment: "Action"), for: .normal)
        learnmoreButton.setTitle(NSLocalizedString("Support ProtonMail", comment: "Action"), for: .normal)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let page : Int = Int( floor((contentScrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
        pageControlView.currentPage = page;
        updateStatusForLastPage()
    }

    func updateStatusForLastPage () {
        if onboardingList[pageControlView.currentPage] == Onboarding.upgrade {
            pageControlView.isHidden = true
            learnmoreButton.isHidden = false
        } else {
            pageControlView.isHidden = false
            learnmoreButton.isHidden = true
        }
    }
    
    @IBAction func learnMoreAction(_ sender: UIButton) {
        UIApplication.shared.openURL(upgradePageUrl)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
