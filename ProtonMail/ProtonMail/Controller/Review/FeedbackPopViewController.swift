//
//  FeedbackViewController.swift
//  ProtonMail - Created on 3/11/16.
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
