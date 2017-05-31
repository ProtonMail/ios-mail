//
//  ToastMessageView.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/22/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


class ToastMessageView : PMView {
    
    override func getNibName() -> String {
        return "ToastMessageView";
    }
    
    override func setup() {
    }
    
    
    
    
    
}


extension ProtonMailViewController {
    func setupToastView() -> ToastMessageView {
        
        let v = ToastMessageView()
        
        self.view.addSubview(v)
        
        let f = CGRect(x: 10, y: self.view.frame.height - 40, width: self.view.frame.width - 10, height: 40)
        
        v.frame = f;
        
        v.backgroundColor = UIColor.black
        return v;
        
        
    }
}
