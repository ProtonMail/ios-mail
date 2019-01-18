//
//  LabelViewModel.swift
//  ProtonMail - Created on 8/17/15.
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
import CoreData


class LabelMessageModel {
    var label : Label!
    var totalMessages : [Message] = []
    var originalSelected : [Message] = []
    var origStatus : Int = 0
    var currentStatus : Int = 0
}

class LabelViewModel {

    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    public init() {
        
    }
    
    func getFetchType() -> LabelFetchType {
        fatalError("This method must be overridden")
    }
    
    func apply (archiveMessage : Bool) -> Bool {
        fatalError("This method must be overridden")
    }
    
    func cancel () {
        fatalError("This method must be overridden")
    }
    
    func getLabelMessage(_ label : Label!) -> LabelMessageModel! {
        fatalError("This method must be overridden")
    }
    
    func cellClicked(_ label : Label!) {
        fatalError("This method must be overridden")
    }
    
    func singleSelectLabel() {
        
    }
    
    func getTitle() -> String {
        fatalError("This method must be overridden")
    }
    
    func showArchiveOption() -> Bool {
        fatalError("This method must be overridden")
    }
    
    func getApplyButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    func getCancelButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    func fetchController() -> NSFetchedResultsController<NSFetchRequestResult>? {
        fatalError("This method must be overridden")
    }
}

