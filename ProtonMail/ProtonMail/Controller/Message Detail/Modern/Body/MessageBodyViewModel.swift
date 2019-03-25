//
//  File.swift
//  ProtonMail - Created on 07/03/2019.
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

class MessageBodyViewModel: NSObject {
    @objc internal dynamic var contents: WebContents
    private var bodyObservation: NSKeyValueObservation!
    private var remoteContentModeObservation: NSKeyValueObservation!
    @objc internal dynamic var contentSize: CGSize = .zero
    
    init(parentViewModel: Standalone) {
        self.contents = WebContents(body: parentViewModel.body, remoteContentMode: parentViewModel.remoteContentMode)
        
        super.init()
        
        self.bodyObservation = parentViewModel.observe(\.body) { [weak self] standalone, _ in
            guard let self = self else { return }
            self.contents = WebContents(body: parentViewModel.body, remoteContentMode: standalone.remoteContentMode)
        }
        self.remoteContentModeObservation = parentViewModel.observe(\.remoteContentModeObservable) { [weak self] standalone, _ in
            guard let self = self else { return }
            self.contents = WebContents(body: parentViewModel.body, remoteContentMode: standalone.remoteContentMode)
        }
    }
}
