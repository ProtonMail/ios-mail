//
//  LabelEditViewModel.swift
//  ProtonMail - Created on 3/2/17.
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


public class LabelEditViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    let colors: [String] = ColorManager.forLabel
    
    public init() {
        
    }
    
    public func colorCount() -> Int {
        return colors.count
    }
    
    public func color(at index : Int) -> String {
        return colors[index]
    }

    public func title() -> String {
        fatalError("This method must be overridden")
    }
    
    public func seletedIndex() -> IndexPath {
        let count = UInt32(colors.count)
        let rand = Int(arc4random_uniform(count))
        return IndexPath(row: rand, section: 0)
    }
    
    public func name() -> String {
        return ""
    }
    
    public func placeHolder() -> String {
        fatalError("This method must be overridden")
    }
    
    public func rightButtonText() -> String {
        fatalError("This method must be overridden")
    }
    
    public func apply(withName name : String, color : String, error:@escaping ErrorBlock, complete:@escaping OkBlock) {
        fatalError("This method must be overridden")
    }

    
//    public func apply (archiveMessage : Bool) {
//        fatalError("This method must be overridden")
//    }
//    
//    public func cancel () {
//        fatalError("This method must be overridden")
//    }

//    
//    public func getLabelMessage(label : Label!) -> LabelMessageModel! {
//        fatalError("This method must be overridden")
//    }

//    
//    public func showArchiveOption() -> Bool {
//        fatalError("This method must be overridden")
//    }
//    
//    public func getApplyButtonText() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    public func getCancelButtonText() -> String {
//        fatalError("This method must be overridden")
//    }
//    
//    public func fetchController() -> NSFetchedResultsController? {
//        fatalError("This method must be overridden")
//    }
}
