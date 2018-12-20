//
//  OnboardingViewController.swift
//  ProtonMail - Created on 2/16/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

class OnboardingViewController : UIViewController, UIScrollViewDelegate {
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var pageControlView: UIPageControl!
    @IBOutlet weak var learnmoreButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    
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
            boardView.config(with: board)
            self.contentScrollView.addSubview(boardView);
        }
        contentScrollView.contentSize = CGSize (width: pageWidth * CGFloat(count), height: contentScrollView.contentSize.height);
        pageControlView.numberOfPages = count;
        pageControlView.currentPage = 0;
        
        closeButton.setTitle(LocalString._close_tour, for: .normal)
        learnmoreButton.setTitle(LocalString._support_protonmail, for: .normal)
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
        UIApplication.shared.openURL(.planUpgradePage)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
