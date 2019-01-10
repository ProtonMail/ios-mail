//
//  PMUIView.swift
//  ProtonMail - Created on 9/9/15.
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


import UIKit

extension PMView {
    @objc func getNibName() -> String {
        fatalError("This method must be overridden")
    }
    
    @objc func setup() -> Void {

    }
}

class PMView: UIView {
    var pmView: UIView!
    
    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)!
        self.setupView()
    }
    
    func setupView() {
        if let pmView = loadViewFromNib() {
            pmView.frame = self.bounds
            pmView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            self.addSubview(pmView)
            pmView.clipsToBounds = true;
            self.clipsToBounds = true;
            self.setup()
        } else {
            PMLog.D("PMView setupView loadViewFromNib failed") //TODO:: add a real log
        }
    }
    
    fileprivate func loadViewFromNib () -> UIView? {
        let bundle = Bundle(for: type(of: self) )
        let nib = UINib(nibName: self.getNibName(), bundle: bundle)
        let views = nib.instantiate(withOwner: self, options: nil)
        if views.count > 0 {
            if let view = views[0] as? UIView {
                return view
            }
        }
        return nil
    }
}
