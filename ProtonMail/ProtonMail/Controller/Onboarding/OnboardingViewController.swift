//
//  OnboardingViewController.swift
//  ProtonMail - Created on 2/16/16.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


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
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(.planUpgradePage, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(.planUpgradePage)
        }
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func closeAction(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}
