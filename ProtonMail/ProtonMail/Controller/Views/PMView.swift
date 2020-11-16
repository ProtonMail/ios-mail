//
//  PMUIView.swift
//  ProtonMail - Created on 9/9/15.
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


import UIKit

extension PMView {
    @objc func getNibName() -> String {
        fatalError("This method must be overridden")
    }
    
    @objc func setup() -> Void {

    }
}

class PMView: UIView, AccessibleView {
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
        generateAccessibilityIdentifiers()
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
