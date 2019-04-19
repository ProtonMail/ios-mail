//
//  EditorViewController.swift
//  ProtonMail - Created on 25/03/2019.
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

class EditorViewController: ComposeViewController {
    internal weak var enclosingScroller: MessageBodyScrollingDelegate?
    private var heightObservation: NSKeyValueObservation!
    private var height: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let defaultHeight = (self.viewModel as! EditorViewModel).contentHeight
        self.height = self.view.heightAnchor.constraint(equalToConstant: defaultHeight)
        self.height.priority = .init(999.0)
        self.height.isActive = true
        
        self.heightObservation = self.htmlEditor.observe(\.contentHeight, options: [.new, .old]) { htmlEditor, change in
            guard change.oldValue != change.newValue else { return }
            let totalHeight = htmlEditor.contentHeight + self.headerView.view.bounds.height
            self.height.constant = totalHeight
            (self.viewModel as! EditorViewModel).contentHeight = totalHeight
        }
    }
    
    override func caretMovedTo(_ offset: CGFloat) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            let offsetAreaInCell = CGRect(x: 0, y: offset, width: 1, height: 100) // FIXME: approx height of our text row
            let offsetArea = self.view.convert(offsetAreaInCell, to: self.enclosingScroller!.scroller)
            self.enclosingScroller?.scroller.scrollRectToVisible(offsetArea, animated: true)
        }
    }
    
    override func composeViewHideExpirationView(_ composeView: ComposeHeaderViewController) {
        super.composeViewHideExpirationView(composeView)
        self.enclosingScroller?.scroller.isScrollEnabled = true
    }
    
    override func composeViewDidTapExpirationButton(_ composeView: ComposeHeaderViewController) {
        super.composeViewDidTapExpirationButton(composeView)
        self.enclosingScroller?.scroller.isScrollEnabled = false
    }
}

class EditorViewModel: ComposeViewModelImpl {
    @objc internal dynamic var contentHeight: CGFloat = 0.0
}
