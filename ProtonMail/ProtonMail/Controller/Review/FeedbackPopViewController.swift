//
//  FeedbackViewController.swift
//  ProtonMail - Created on 3/11/16.
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
