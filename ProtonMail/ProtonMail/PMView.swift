//
//  PMUIView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/9/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

import UIKit

extension PMView {
    func getNibName() -> String {
        fatalError("This method must be overridden")
    }
    
    func setup() -> Void {
       
    }
}

class PMView: UIView {
    var pmView: UIView!
    
    override init(frame: CGRect) { // for using CustomView in code
        super.init(frame: frame)
        setupView()
    }
    
    required init(coder aDecoder: NSCoder) { // for using CustomView in IB
        super.init(coder: aDecoder)
        self.setupView()
    }
    
    func setupView() {
        pmView = loadViewFromNib()
        pmView.frame = self.bounds
        pmView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        self.addSubview(pmView)
        pmView.clipsToBounds = true;
        self.clipsToBounds = true;
        self.setup()
    }
    
    private func loadViewFromNib () -> UIView {
        let bundle = NSBundle(forClass: self.dynamicType )
        let nib = UINib(nibName: self.getNibName(), bundle: bundle)
        var view = nib.instantiateWithOwner(self, options: nil)[0] as! UIView
        
        return view;
    }
}