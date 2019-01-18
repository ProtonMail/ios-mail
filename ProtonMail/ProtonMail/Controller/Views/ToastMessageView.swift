//
//  ToastMessageView.swift
//  ProtonMail - Created on 3/22/17.
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
