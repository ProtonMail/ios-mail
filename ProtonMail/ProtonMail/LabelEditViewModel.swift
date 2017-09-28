//
//  LabelEditViewModel.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 3/2/17.
//  Copyright © 2017 ProtonMail. All rights reserved.
//

import Foundation


public class LabelEditViewModel {
    
    public typealias OkBlock = () -> Void
    public typealias ErrorBlock = (_ code : Int, _ errorMessage : String) -> Void
    
    let colors : [String] = ["#7272a7","#cf5858", "#c26cc7", "#7569d1", "#69a9d1", "#5ec7b7", "#72bb75", "#c3d261", "#e6c04c", "#e6984c", "#8989ac", "#cf7e7e", "#c793ca", "#9b94d1", "#a8c4d5", "#97c9c1", "#9db99f", "#c6cd97", "#e7d292", "#dfb286"]
    
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
